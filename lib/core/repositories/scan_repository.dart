import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../database/scan_database.dart';
import '../models/scan_model.dart';
import '../services/scan_image_store.dart';

class ScanRepository {
  final ScanDatabase _database = ScanDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate content-based hash for duplicate detection
  /// NOTE: includes scan source + imagePath hash + minute bucket
  String _generateContentHash(Map<String, dynamic> data, String? imagePath) {
    final plantName = data['plantName']?.toString() ??
        data['plant']?.toString() ??
        (data['data'] is Map ? (data['data']['plant']?.toString()) : null) ??
        '';

    final diseaseName = data['diseaseName']?.toString() ??
        data['diagnosis']?.toString() ??
        (data['data'] is Map ? (data['data']['disease']?.toString()) : null) ??
        '';

    final confidence = data['confidence']?.toString() ??
        (data['data'] is Map ? (data['data']['confidence']?.toString()) : null) ??
        '0';

    // For advanced scans, include source
    final source = data['source']?.toString() ?? data['analysisSource']?.toString() ?? '';

    final fingerprint = {
      'plant': plantName.toLowerCase().trim(),
      'disease': diseaseName.toLowerCase().trim(),
      'confidence': confidence,
      'source': source.toLowerCase().trim(),
      'imageHash': imagePath?.hashCode ?? 0,
      // Round to nearest minute so quick repeats become duplicates
      'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 60000),
    };

    final hash = jsonEncode(fingerprint).hashCode.abs();

    final src = source.toLowerCase();
    final isAdvancedSource = src.contains('groq') ||
        src.contains('plantid') ||
        src.contains('plant.id') ||
        src.contains('planthealth') ||
        src.contains('advanced');

    return isAdvancedSource ? 'advanced_$hash' : 'ondevice_$hash';
  }

  Future<ScanModel> saveOnDeviceScan({
    required Map<String, dynamic> scanData,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final scanId = scanData['id'] as String? ?? _generateContentHash(scanData, imagePath);

      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ On-device scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Keep a compressed copy in app storage; the camera cache can be wiped.
      final storedPath = await ScanImageStore.saveFromFile(scanId, imagePath) ?? imagePath;

      final scan = ScanModel.fromOnDeviceScan(
        userId: user.uid,
        scanData: scanData,
        imagePath: storedPath,
      ).copyWith(
        id: scanId,
      );

      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      _syncOnDeviceScanToFirebase(savedScan);

      debugPrint('✅ On-device scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') || e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate scan detected, fetching existing');
        final scanId = scanData['id'] as String? ?? _generateContentHash(scanData, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving on-device scan: $e');
      rethrow;
    }
  }

  /// Utility: clean duplicates in SQLite
  Future<void> cleanDuplicateScans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final allScans = await _database.getScansByUser(user.uid, limit: 1000);
      final uniqueScans = <String, ScanModel>{};

      for (final scan in allScans) {
        final key = '${scan.plantName}_${scan.diseaseName}_${scan.scanDate.millisecondsSinceEpoch}';
        if (!uniqueScans.containsKey(key)) {
          uniqueScans[key] = scan;
        } else {
          await _database.deleteScan(scan.id!);
          debugPrint('🗑️ Deleted duplicate scan: ${scan.id}');
        }
      }

      debugPrint('✅ Cleaned duplicates, kept ${uniqueScans.length} unique scans');
    } catch (e) {
      debugPrint('❌ Error cleaning duplicates: $e');
    }
  }

  Future<ScanModel> saveGroqScan({
    required Map<String, dynamic> analysisResult,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);

      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ Groq scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Keep a compressed copy in app storage; the camera cache can be wiped.
      final storedPath = await ScanImageStore.saveFromFile(scanId, imagePath) ?? imagePath;

      final scan = ScanModel.fromGroqScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: storedPath,
      ).copyWith(
        id: scanId,
      );

      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      _syncAdvancedScanToFirebase(savedScan);

      debugPrint('✅ Groq scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') || e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate Groq scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving Groq scan: $e');
      rethrow;
    }
  }

  Future<ScanModel> savePlantIdScan({
    required Map<String, dynamic> analysisResult,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);

      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ Plant.id scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Keep a compressed copy in app storage; the camera cache can be wiped.
      final storedPath = await ScanImageStore.saveFromFile(scanId, imagePath) ?? imagePath;

      final scan = ScanModel.fromPlantIdScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: storedPath,
      ).copyWith(
        id: scanId,
      );

      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      _syncAdvancedScanToFirebase(savedScan);

      debugPrint('✅ Plant.id scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') || e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate Plant.id scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving Plant.id scan: $e');
      rethrow;
    }
  }

  /// PlantHealth advanced scan save
  Future<ScanModel> savePlantHealthScan({
    required Map<String, dynamic> analysisResult,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);

      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ PlantHealth scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Keep a compressed copy in app storage; the camera cache can be wiped.
      final storedPath = await ScanImageStore.saveFromFile(scanId, imagePath) ?? imagePath;

      final scan = ScanModel.fromPlantHealthScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: storedPath,
      ).copyWith(
        id: scanId,
      );

      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      _syncAdvancedScanToFirebase(savedScan);

      debugPrint('✅ PlantHealth scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') || e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate PlantHealth scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ?? _generateContentHash(data, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving PlantHealth scan: $e');
      rethrow;
    }
  }

  Future<void> checkForDuplicates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final allScans = await getUserScans(limit: 1000);
      debugPrint('🔍 Checking for duplicates among ${allScans.length} scans');

      final Map<String, List<ScanModel>> duplicates = {};

      for (final scan in allScans) {
        final key = '${scan.plantName}_${scan.diseaseName}_${scan.scanDate.millisecondsSinceEpoch}';
        duplicates.putIfAbsent(key, () => []);
        duplicates[key]!.add(scan);
      }

      int duplicateCount = 0;
      duplicates.forEach((key, scans) {
        if (scans.length > 1) {
          duplicateCount++;
          debugPrint('⚠️ Found ${scans.length} duplicates for key: $key');
          for (final scan in scans) {
            debugPrint('   - ID: ${scan.id}, Created: ${scan.createdAt}');
          }
        }
      });

      debugPrint('📊 Total duplicates found: $duplicateCount');
    } catch (e) {
      debugPrint('❌ Error checking duplicates: $e');
    }
  }

  Future<ScanModel?> getScanById(String id) async {
    try {
      return await _database.getScanById(id);
    } catch (e) {
      debugPrint('❌ Error getting scan by ID $id: $e');
      return null;
    }
  }

  Future<bool> scanExists(String scanId) async {
    try {
      final scan = await _database.getScanById(scanId);
      return scan != null;
    } catch (e) {
      debugPrint('❌ Error checking if scan exists: $e');
      return false;
    }
  }

  /// Firestore documents are capped at 1 MiB. Photos are stored compressed
  /// (~100-300 KB), so they normally fit; if one is still too large it is left
  /// out of the cloud copy rather than failing the whole sync.
  static const int _maxCloudImageChars = 700 * 1024;

  Future<Map<String, dynamic>> _firestorePayload(ScanModel scan) async {
    final data = scan.toFirestore();
    var image = data['imageBase64'] as String?;
    if (image == null || image.isEmpty) {
      image = await ScanImageStore.readBase64(scan.imagePath);
    }
    if (image != null && image.length <= _maxCloudImageChars) {
      data['imageBase64'] = image;
    } else {
      data.remove('imageBase64');
    }
    // The local file path means nothing on another device.
    data['imagePath'] = '';
    return data;
  }

  /// One-time upgrade for scans saved by older versions, which kept the photo
  /// as base64 text inside SQLite. Moves each one into a file and clears the
  /// column. Safe to call repeatedly; does nothing once everything is moved.
  Future<void> migrateInlineImagesToFiles() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final ids = await _database.getIdsWithInlineImage(user.uid);
      for (final id in ids) {
        try {
          final scan = await _database.getScanById(id);
          final path = await ScanImageStore.saveFromBase64(id, scan?.imageBase64);
          if (path != null) await _database.setImageFile(id, path);
        } catch (e) {
          debugPrint('⚠️ Could not migrate image for scan $id: $e');
        }
      }
      if (ids.isNotEmpty) debugPrint('✅ Migrated ${ids.length} scan images to files');
    } catch (e) {
      debugPrint('⚠️ Image migration failed: $e');
    }
  }

  /// Removes all local scans (and their photo files) for [userId].
  Future<void> deleteLocalScansForUser(String userId) async {
    try {
      final scans = await _database.getScansByUser(userId, limit: 100000);
      for (final scan in scans) {
        await ScanImageStore.delete(scan.imagePath);
      }
    } catch (e) {
      debugPrint('⚠️ Could not remove scan image files: $e');
    }
    await _database.deleteScansForUser(userId);
  }

  static String? _restoredForUid;

  /// Downloads this user's cloud scans that are missing from the local
  /// database (new phone, reinstall, cleared app data). Runs once per user
  /// per app session. Returns how many scans were restored.
  Future<int> restoreFromCloud({bool force = false}) async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    if (!force && _restoredForUid == user.uid) return 0;

    var restored = 0;
    try {
      final localIds = (await _database.getScansByUser(user.uid, limit: 100000))
          .map((s) => s.id)
          .toSet();

      for (final collection in const ['onDeviceScans', 'advancedScans']) {
        final snap = await _firestore
            .collection(collection)
            .where('userId', isEqualTo: user.uid)
            .get();
        for (final doc in snap.docs) {
          if (localIds.contains(doc.id)) continue;
          try {
            final fromCloud = ScanModel.fromFirestore(doc);
            // The cloud imagePath points at a file on the old device; rebuild
            // the photo locally from the backed-up base64 instead.
            final path = await ScanImageStore.saveFromBase64(doc.id, fromCloud.imageBase64);
            final scan = fromCloud.copyWith(
              imagePath: path ?? '',
              clearImageBase64: true,
              isSynced: true,
            );
            await _database.createScan(scan);
            restored++;
          } catch (e) {
            debugPrint('⚠️ Could not restore scan ${doc.id}: $e');
          }
        }
      }
      _restoredForUid = user.uid;
      debugPrint('✅ Restored $restored scans from cloud');
    } catch (e) {
      debugPrint('⚠️ Cloud restore failed (will retry next launch): $e');
    }
    return restored;
  }

  Future<void> _syncOnDeviceScanToFirebase(ScanModel scan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (scan.isSynced) {
        debugPrint('✅ Scan already synced to Firestore: ${scan.id}');
        return;
      }

      final updatedScan = scan.copyWith(imageUrl: '');

      await _firestore.collection('onDeviceScans').doc(scan.id).set(await _firestorePayload(updatedScan));
      await _database.markAsSynced(scan.id!);

      debugPrint('✅ On-Device scan synced to Firestore: ${scan.id}');
    } catch (e) {
      debugPrint('⚠️ Error syncing to Firestore: $e');
    }
  }

  Future<void> _syncAdvancedScanToFirebase(ScanModel scan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (scan.isSynced) {
        debugPrint('✅ Advanced scan already synced to Firestore: ${scan.id}');
        return;
      }

      final updatedScan = scan.copyWith(imageUrl: '');

      await _firestore.collection('advancedScans').doc(scan.id).set(await _firestorePayload(updatedScan));
      await _database.markAsSynced(scan.id!);

      debugPrint('✅ Advanced scan synced to Firestore: ${scan.id}');
    } catch (e) {
      debugPrint('⚠️ Error syncing to Firestore: $e');
    }
  }

  Future<List<ScanModel>> getUserScans({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      return await _database.getScansByUser(user.uid, limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting user scans: $e');
      return [];
    }
  }

  Future<List<ScanModel>> getOnDeviceScans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      return await _database.getOnDeviceScans(user.uid);
    } catch (e) {
      debugPrint('❌ Error getting on-device scans: $e');
      return [];
    }
  }

  Future<List<ScanModel>> getAdvancedScans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      return await _database.getAdvancedScans(user.uid);
    } catch (e) {
      debugPrint('❌ Error getting advanced scans: $e');
      return [];
    }
  }

  Future<List<ScanModel>> getScansBySource(AnalysisSource source) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      return await _database.getScansBySource(user.uid, source.name);
    } catch (e) {
      debugPrint('❌ Error getting scans by source: $e');
      return [];
    }
  }

  Future<void> deleteScan(String scanId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final scan = await _database.getScanById(scanId);

      if (scan != null) {
        final collection = scan.scanType == ScanType.onDevice ? 'onDeviceScans' : 'advancedScans';

        try {
          await _firestore.collection(collection).doc(scanId).delete();
          debugPrint('✅ Scan deleted from Firestore: $scanId');
        } catch (e) {
          debugPrint('⚠️ Error deleting from Firestore (might not exist): $e');
        }

        await _database.deleteScan(scanId);
        await ScanImageStore.delete(scan.imagePath);
        debugPrint('✅ Scan deleted from SQLite: $scanId');
      } else {
        debugPrint('⚠️ Scan not found: $scanId');
      }
    } catch (e) {
      debugPrint('❌ Error deleting scan: $e');
      rethrow;
    }
  }

  Future<void> syncUnsyncedScans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final unsyncedScans = await _database.getUnsyncedScans(user.uid);

      if (unsyncedScans.isEmpty) {
        debugPrint('✅ All scans are synced');
        return;
      }

      debugPrint('🔄 Syncing ${unsyncedScans.length} unsynced scans');

      for (final scan in unsyncedScans) {
        try {
          if (scan.scanType == ScanType.onDevice) {
            await _syncOnDeviceScanToFirebase(scan);
          } else {
            await _syncAdvancedScanToFirebase(scan);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to sync scan ${scan.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing unsynced scans: $e');
    }
  }

  Future<Map<String, dynamic>> getScanStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final counts = await _database.getScanCounts(user.uid);
      final allScans = await getUserScans(limit: 100);

      return {
        'totalScans': counts['total'] ?? 0,
        'onDeviceScans': counts['onDevice'] ?? 0,
        'advancedScans': counts['advanced'] ?? 0,
        'mostCommonDisease': _getMostCommonDisease(allScans),
        'recentScan': allScans.isNotEmpty ? allScans.first.scanDate : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting scan statistics: $e');
      return {};
    }
  }

  String _getMostCommonDisease(List<ScanModel> scans) {
    if (scans.isEmpty) return 'None';

    final diseaseCounts = <String, int>{};
    for (final scan in scans) {
      if (scan.diseaseName.toLowerCase() != 'healthy') {
        diseaseCounts[scan.diseaseName] = (diseaseCounts[scan.diseaseName] ?? 0) + 1;
      }
    }

    if (diseaseCounts.isEmpty) return 'Healthy';

    return diseaseCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<void> clearAllLocalScans() async {
    try {
      await _database.clearAllScans();
      debugPrint('✅ All local scans cleared');
    } catch (e) {
      debugPrint('❌ Error clearing local scans: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      return await _database.getDatabaseInfo();
    } catch (e) {
      debugPrint('❌ Error getting database info: $e');
      return {};
    }
  }

  Future<void> close() async {
    try {
      await _database.close();
      debugPrint('✅ Scan repository closed');
    } catch (e) {
      debugPrint('⚠️ Error closing repository: $e');
    }
  }
}