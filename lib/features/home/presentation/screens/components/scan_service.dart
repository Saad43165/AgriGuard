// scan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchRecentScans() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Check if image exists locally
        final localPath = data['localImagePath'];
        if (localPath != null) {
          final file = File(localPath);
          data['localImageExists'] = file.existsSync();
        }
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching scans: $e');
      throw Exception('Failed to fetch recent scans: $e');
    }
  }

  Future<void> saveScan(Map<String, dynamic> scan, {File? imageFile}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Generate scan ID
      final scanId = _firestore.collection('users').doc(uid).collection('scans').doc().id;

      String? localImagePath;

      // Copy image to app's local directory if provided
      if (imageFile != null) {
        localImagePath = await _saveImageLocally(imageFile, scanId);
        debugPrint('Image saved locally: $localImagePath');
      }

      // Prepare scan data
      final scanData = {
        ...scan,
        'id': scanId,
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'localImagePath': localImagePath, // Store local path
        'hasCloudImage': false, // Mark as local storage
        'status': scan['status'] ?? 'pending',
        'diagnosis': scan['diagnosis'],
        'confidence': scan['confidence'],
        'treatment': scan['treatment'],
        'cropType': scan['cropType'],
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(scanId)
          .set(scanData);

      // Update user scan count
      await _updateUserScanCount(uid);

      debugPrint('Scan saved successfully: $scanId');
    } catch (e) {
      debugPrint('Error saving scan: $e');
      throw Exception('Failed to save scan: ${e.toString()}');
    }
  }

  Future<String> _saveImageLocally(File imageFile, String scanId) async {
    try {
      // Get app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final scansDirectory = Directory('${directory.path}/scans');

      // Create scans directory if it doesn't exist
      if (!await scansDirectory.exists()) {
        await scansDirectory.create(recursive: true);
      }

      // Create unique filename
      final fileName = 'scan_${scanId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${scansDirectory.path}/$fileName';

      // Copy the file to local storage
      await imageFile.copy(localPath);

      return localPath;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      rethrow;
    }
  }

  Future<File?> getLocalImage(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local image: $e');
      return null;
    }
  }

  Future<void> deleteScan(String scanId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Get scan data first to find local image path
      final scanDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(scanId)
          .get();

      if (scanDoc.exists) {
        final data = scanDoc.data();
        final localPath = data?['localImagePath'];

        // Delete local image file if it exists
        if (localPath != null) {
          await _deleteLocalImage(localPath);
        }

        // Delete scan document from Firestore
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('scans')
            .doc(scanId)
            .delete();

        debugPrint('Scan deleted: $scanId');

        // Update user scan count
        await _decrementUserScanCount(uid);
      }
    } catch (e) {
      debugPrint('Error deleting scan: $e');
      throw Exception('Failed to delete scan: ${e.toString()}');
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
      debugPrint('Error deleting local image: $e');
      // Continue even if local deletion fails
    }
  }

  Future<void> clearAllLocalScans() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Get all scans for the user
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scans')
          .get();

      // Delete all local images
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final localPath = data['localImagePath'];
        if (localPath != null) {
          await _deleteLocalImage(localPath);
        }
      }

      // Clear scans directory
      final directory = await getApplicationDocumentsDirectory();
      final scansDirectory = Directory('${directory.path}/scans');
      if (await scansDirectory.exists()) {
        await scansDirectory.delete(recursive: true);
      }

      debugPrint('All local scans cleared');
    } catch (e) {
      debugPrint('Error clearing local scans: $e');
    }
  }

  Future<void> _updateUserScanCount(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (userDoc.exists) {
          final currentCount = (userDoc.data()?['scanCount'] ?? 0) as int;
          transaction.update(userDocRef, {
            'scanCount': currentCount + 1,
            'lastScan': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(userDocRef, {
            'scanCount': 1,
            'lastScan': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating user scan count: $e');
    }
  }

  Future<void> _decrementUserScanCount(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);
        if (userDoc.exists) {
          final currentCount = (userDoc.data()?['scanCount'] ?? 0) as int;
          final newCount = currentCount > 0 ? currentCount - 1 : 0;

          transaction.update(userDocRef, {
            'scanCount': newCount,
          });
        }
      });
    } catch (e) {
      debugPrint('Error decrementing user scan count: $e');
    }
  }
}