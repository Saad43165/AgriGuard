import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../database/scan_database.dart';
import '../models/scan_model.dart';

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

      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
            debugPrint('📸 Image converted to base64, size: ${bytes.length} bytes');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final scan = ScanModel.fromOnDeviceScan(
        userId: user.uid,
        scanData: scanData,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
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

      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBase64 = base64Encode(await file.readAsBytes());
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final scan = ScanModel.fromGroqScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
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

      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBase64 = base64Encode(await file.readAsBytes());
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final scan = ScanModel.fromPlantIdScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
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

      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBase64 = base64Encode(await file.readAsBytes());
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final scan = ScanModel.fromPlantHealthScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
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

  Future<void> _syncOnDeviceScanToFirebase(ScanModel scan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (scan.isSynced) {
        debugPrint('✅ Scan already synced to Firestore: ${scan.id}');
        return;
      }

      final updatedScan = scan.copyWith(imageUrl: '');

      await _firestore.collection('onDeviceScans').doc(scan.id).set(updatedScan.toFirestore());
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

      await _firestore.collection('advancedScans').doc(scan.id).set(updatedScan.toFirestore());
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