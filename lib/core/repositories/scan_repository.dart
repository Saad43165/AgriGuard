import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../database/scan_database.dart';
import '../models/scan_model.dart';

class ScanRepository {
  final ScanDatabase _database = ScanDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to generate content-based hash for duplicate detection
// In ScanRepository.dart, update the _generateContentHash method:
  String _generateContentHash(Map<String, dynamic> data, String? imagePath) {
    // Extract key data points
    final plantName = data['plantName']?.toString() ??
        data['plant']?.toString() ??
        data['data']?['plant']?.toString() ?? '';

    final diseaseName = data['diseaseName']?.toString() ??
        data['diagnosis']?.toString() ??
        data['data']?['disease']?.toString() ?? '';

    final confidence = data['confidence']?.toString() ??
        data['data']?['confidence']?.toString() ?? '0';

    // For advanced scans, include source
    final source = data['source']?.toString() ??
        data['analysisSource']?.toString() ?? '';

    // Create a fingerprint for duplicate detection
    final fingerprint = {
      'plant': plantName.toLowerCase().trim(),
      'disease': diseaseName.toLowerCase().trim(),
      'confidence': confidence,
      'source': source.toLowerCase().trim(),
      'imageHash': imagePath?.hashCode ?? 0,
      'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 60000), // Round to nearest minute
    };

    final jsonString = jsonEncode(fingerprint);
    final hash = jsonString.hashCode.abs();

    // Include source in ID to differentiate between on-device and advanced scans
    if (source.contains('groq') ||
        source.contains('plantid') ||
        source.contains('hugging') ||
        source.contains('hf') ||
        source.contains('advanced')) {
      return 'advanced_$hash';
    } else {
      return 'ondevice_$hash';
    }
  }
  Future<ScanModel> saveOnDeviceScan({
    required Map<String, dynamic> scanData,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Use provided ID or generate new one
      final scanId = scanData['id'] as String? ??
          _generateContentHash(scanData, imagePath);

      // Check if scan already exists
      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ On-device scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Convert image to base64
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

      // Create scan model with the ID
      final scan = ScanModel.fromOnDeviceScan(
        userId: user.uid,
        scanData: scanData,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
        id: scanId, // Use the provided/generated ID
      );

      // Save to SQLite
      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      // Sync to Firebase in background
      _syncOnDeviceScanToFirebase(savedScan);

      debugPrint('✅ On-device scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      // Handle duplicate constraint errors gracefully
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate scan detected, fetching existing');
        final scanId = scanData['id'] as String? ??
            _generateContentHash(scanData, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving on-device scan: $e');
      rethrow;
    }
  }
// Add this to ScanRepository
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
          // Delete duplicate
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

      // Extract data for hash generation
      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ??
          _generateContentHash(data, imagePath);

      // Check if scan already exists
      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ Groq scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Convert image to base64
      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      // Create scan model
      final scan = ScanModel.fromGroqScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
        id: scanId,
      );

      // Save to SQLite
      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      // Sync to Firebase in background
      _syncAdvancedScanToFirebase(savedScan);

      debugPrint('✅ Groq scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate Groq scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ??
            _generateContentHash(data, imagePath);
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

      // Extract data for hash generation
      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ??
          _generateContentHash(data, imagePath);

      // Check if scan already exists
      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ Plant.id scan already exists, returning existing: $scanId');
        return existingScan;
      }

      // Convert image to base64
      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      // Create scan model
      final scan = ScanModel.fromPlantIdScan(
        userId: user.uid,
        analysisResult: analysisResult,
        imagePath: imagePath,
      ).copyWith(
        imageBase64: imageBase64,
        id: scanId,
      );

      // Save to SQLite
      final savedScanId = await _database.createScan(scan);
      final savedScan = scan.copyWith(id: savedScanId);

      // Sync to Firebase in background
      _syncAdvancedScanToFirebase(savedScan);

      debugPrint('✅ Plant.id scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate Plant.id scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ??
            _generateContentHash(data, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving Plant.id scan: $e');
      rethrow;
    }
  }

  Future<ScanModel> saveHuggingFaceScan({
    required Map<String, dynamic> analysisResult,
    String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
      final scanId = analysisResult['scanId'] as String? ??
          _generateContentHash(data, imagePath);

      final existingScan = await _database.getScanById(scanId);
      if (existingScan != null) {
        debugPrint('✅ Hugging Face scan already exists, returning existing: $scanId');
        return existingScan;
      }

      String? imageBase64;
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to convert image to base64: $e');
        }
      }

      final scan = ScanModel.fromHuggingFaceScan(
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

      debugPrint('✅ Hugging Face scan saved: $savedScanId');
      return savedScan;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('Duplicate')) {
        debugPrint('⚠️ Duplicate Hugging Face scan detected');
        final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
        final scanId = analysisResult['scanId'] as String? ??
            _generateContentHash(data, imagePath);
        final existing = await _database.getScanById(scanId);
        if (existing != null) return existing;
      }
      debugPrint('❌ Error saving Hugging Face scan: $e');
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
        if (!duplicates.containsKey(key)) {
          duplicates[key] = [];
        }
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
  // Get a scan by ID - with improved error handling
  Future<ScanModel?> getScanById(String id) async {
    try {
      return await _database.getScanById(id);
    } catch (e) {
      debugPrint('❌ Error getting scan by ID $id: $e');
      return null;
    }
  }

  // Check if scan already exists
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

      // Check if already synced
      if (scan.isSynced) {
        debugPrint('✅ Scan already synced to Firestore: ${scan.id}');
        return;
      }

      final updatedScan = scan.copyWith(imageUrl: '');

      await _firestore
          .collection('onDeviceScans')
          .doc(scan.id)
          .set(updatedScan.toFirestore());

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

      // Check if already synced
      if (scan.isSynced) {
        debugPrint('✅ Advanced scan already synced to Firestore: ${scan.id}');
        return;
      }

      final updatedScan = scan.copyWith(imageUrl: '');

      await _firestore
          .collection('advancedScans')
          .doc(scan.id)
          .set(updatedScan.toFirestore());

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

        // Delete from Firestore
        try {
          await _firestore
              .collection(collection)
              .doc(scanId)
              .delete();
          debugPrint('✅ Scan deleted from Firestore: $scanId');
        } catch (e) {
          debugPrint('⚠️ Error deleting from Firestore (might not exist): $e');
        }

        // Delete from SQLite
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

    return diseaseCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Additional utility method: Clear all local scans (for debugging)
  Future<void> clearAllLocalScans() async {
    try {
      await _database.clearAllScans();
      debugPrint('✅ All local scans cleared');
    } catch (e) {
      debugPrint('❌ Error clearing local scans: $e');
      rethrow;
    }
  }

  // Get database info for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      return await _database.getDatabaseInfo();
    } catch (e) {
      debugPrint('❌ Error getting database info: $e');
      return {};
    }
  }

  // Close database connection (call when app closes)
  Future<void> close() async {
    try {
      await _database.close();
      debugPrint('✅ Scan repository closed');
    } catch (e) {
      debugPrint('⚠️ Error closing repository: $e');
    }
  }
}