import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../home/screens/components/scan_service.dart';

/// Manages scan operations including saving, retrieving, and validating scans
class ScanManager {
  final ScanService _scanService = ScanService();

  /// Auto-save scan with duplicate detection
  Future<bool> autoSaveScan(Map<String, dynamic> scanData) async {
    try {
      // Get existing scans
      final existingScans = await _scanService.getSavedScans();

      // Generate unique ID
      final scanId = scanData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Check for duplicates
      final isAlreadySaved = existingScans.any(
            (scan) => scan['id'] == scanId,
      );

      if (isAlreadySaved) {
        debugPrint('Scan already saved: $scanId');
        return true;
      }

      // Prepare scan data
      final preparedData = _prepareScanData(scanData, scanId);

      // Save to storage
      await _scanService.saveScan(preparedData);

      debugPrint('Scan auto-saved successfully: $scanId');
      return true;
    } catch (e) {
      debugPrint('Auto-save failed: $e');
      return false;
    }
  }

  /// Prepare scan data for saving with proper type handling
  Map<String, dynamic> _prepareScanData(
      Map<String, dynamic> scanData,
      String scanId,
      ) {
    // Handle timestamp conversion
    dynamic timestampToSave = scanData['timestamp'];
    if (timestampToSave is Timestamp) {
      timestampToSave = timestampToSave.toDate().toIso8601String();
    } else if (timestampToSave == null) {
      timestampToSave = DateTime.now().toIso8601String();
    }

    return {
      'id': scanId,
      'imageUrl': scanData['imageUrl'],
      'imagePath': scanData['imagePath'],
      'diagnosis': scanData['diagnosis'] ?? 'Unknown Disease',
      'confidence': scanData['confidence']?.toString() ?? '0',
      'treatment': scanData['treatment'] ?? 'Consult an expert',
      'timestamp': timestampToSave,
      'severity': scanData['severity'] ?? 'Unknown',
      'plantName': scanData['plantName'] ?? 'Unknown',
      'cropType': scanData['cropType'] ?? 'Unknown',
    };
  }

  /// Get all saved scans
  Future<List<Map<String, dynamic>>> getSavedScans() async {
    try {
      return await _scanService.getSavedScans();
    } catch (e) {
      debugPrint('Failed to retrieve scans: $e');
      return [];
    }
  }

  /// Delete a specific scan
  Future<bool> deleteScan(String scanId) async {
    try {
      await _scanService.deleteScan(scanId);
      return true;
    } catch (e) {
      debugPrint('Failed to delete scan: $e');
      return false;
    }
  }

  /// Check if scan exists
  Future<bool> scanExists(String scanId) async {
    try {
      final scans = await getSavedScans();
      return scans.any((scan) => scan['id'] == scanId);
    } catch (e) {
      debugPrint('Failed to check scan existence: $e');
      return false;
    }
  }

  /// Get scan count
  Future<int> getScanCount() async {
    try {
      final scans = await getSavedScans();
      return scans.length;
    } catch (e) {
      debugPrint('Failed to get scan count: $e');
      return 0;
    }
  }
}