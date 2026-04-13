// lib/features/scan_history/data/scan_service.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection path: users/{uid}/scans
  CollectionReference _userScansCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('scans');

  /* --------------------------------------------------------------------- *
   *  Fetch Recent Scans
   * --------------------------------------------------------------------- */
  Future<List<Map<String, dynamic>>> fetchRecentScans({int limit = 10}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final snapshot = await _userScansCollection(uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final localPath = data['localImagePath'] as String?;
        data['id'] = doc.id;
        data['localImageExists'] = localPath != null && File(localPath).existsSync();
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching scans: $e');
      rethrow;
    }
  }

  /* --------------------------------------------------------------------- *
   *  Save Scan (with local + cloud sync)
   * --------------------------------------------------------------------- */
  Future<String> saveScan(Map<String, dynamic> scanData, {File? imageFile}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? imageUrl;
    String? localImagePath;
    String scanId = '';

    try {
      // 1. Upload image to Firebase Storage
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('scans/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await ref.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // 2. Save image locally and get path
      if (imageFile != null) {
        scanId = _firestore.collection('temp').doc().id; // Pre-generate ID
        localImagePath = await _saveImageLocally(imageFile, scanId);
      }

      // 3. Prepare data
      final data = {
        ...scanData,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'localImagePath': localImagePath,
      };

      // 4. Save to Firestore (transaction for safety)
      await _firestore.runTransaction((transaction) async {
        final docRef = _userScansCollection(user.uid).doc();
        scanId = docRef.id; // Use actual ID
        if (localImagePath != null && imageFile != null) {
          // Re-save with correct ID
          final correctedPath = await _saveImageLocally(imageFile, scanId);
          data['localImagePath'] = correctedPath;
        }
        transaction.set(docRef, data);
      });

      // 5. Update user stats
      unawaited(_updateUserScanCount(user.uid));

      debugPrint('Scan saved: $scanId');
      return scanId;
    } catch (e) {
      debugPrint('Error saving scan: $e');
      // Cleanup on failure
      if (imageUrl != null) {
        await _storage.refFromURL(imageUrl).delete().catchError((_) {});
      }
      if (localImagePath != null) {
        await _deleteLocalImage(localImagePath).catchError((_) {});
      }
      rethrow;
    }
  }

  /* --------------------------------------------------------------------- *
   *  Delete Scan (Firestore + Storage + Local)
   * --------------------------------------------------------------------- */
  Future<void> deleteScan(String scanId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final docRef = _userScansCollection(uid).doc(scanId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Delete in parallel
      await Future.wait([
        // 1. Delete Firestore doc
        docRef.delete(),

        // 2. Delete cloud image
        if (data['imageUrl'] != null)
          _storage.refFromURL(data['imageUrl'] as String).delete().catchError((_) {}),

        // 3. Delete local image
        if (data['localImagePath'] != null)
          _deleteLocalImage(data['localImagePath'] as String),
      ]);

      // 4. Update scan count
      unawaited(_decrementUserScanCount(uid));

      debugPrint('Scan deleted: $scanId');
    } catch (e) {
      debugPrint('Error deleting scan: $e');
      rethrow;
    }
  }

  /* --------------------------------------------------------------------- *
   *  Local Image Management
   * --------------------------------------------------------------------- */
  Future<String> _saveImageLocally(File imageFile, String scanId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${directory.path}/scans');
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      final fileName = 'scan_${scanId}_thumb.jpg';
      final localPath = '${scansDir.path}/$fileName';

      // Compress & copy
      await imageFile.copy(localPath);
      debugPrint('Image saved locally: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('Error saving local image: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalImage(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Local image deleted: $localPath');
      }
    } catch (e) {
      debugPrint('Failed to delete local image: $e');
    }
  }

  Future<File?> getLocalImage(String localPath) async {
    try {
      final file = File(localPath);
      return await file.exists() ? file : null;
    } catch (e) {
      debugPrint('Error reading local image: $e');
      return null;
    }
  }

  /* --------------------------------------------------------------------- *
   *  Clear Local Cache Only
   * --------------------------------------------------------------------- */
  Future<void> clearAllLocalScans() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${directory.path}/scans');
      if (await scansDir.exists()) {
        await scansDir.delete(recursive: true);
        debugPrint('Local scans directory cleared');
      }
    } catch (e) {
      debugPrint('Error clearing local scans: $e');
    }
  }

  /* --------------------------------------------------------------------- *
   *  User Stats (Scan Count)
   * --------------------------------------------------------------------- */
  Future<void> _updateUserScanCount(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final current = (snapshot.data()?['scanCount'] ?? 0) as int;
        transaction.set(userRef, {
          'scanCount': current + 1,
          'lastScan': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error updating scan count: $e');
    }
  }

  Future<void> _decrementUserScanCount(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;
        final current = (snapshot.data()?['scanCount'] ?? 0) as int;
        final newCount = current > 0 ? current - 1 : 0;
        transaction.update(userRef, {'scanCount': newCount});
      });
    } catch (e) {
      debugPrint('Error decrementing scan count: $e');
    }
  }
}