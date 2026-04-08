import 'dart:async';
import '../../../../core/repositories/scan_repository.dart';
import '../models/leaf_analysis_result.dart';
import '../utils/data_parsers.dart';
import '../utils/constants.dart';

class ScanSaveService {
  final ScanRepository _scanRepository;
  final String scanIdPrefix;

  ScanSaveService({
    required ScanRepository scanRepository,
    this.scanIdPrefix = ResultScreenConstants.scanIdPrefix,
  }) : _scanRepository = scanRepository;

  Future<bool> shouldSkipSave(Map<String, dynamic> scanData) {
    return Future.value(
      scanData['isFromHistory'] == true ||
          scanData['skipSave'] == true ||
          scanData['databaseId'] != null ||
          scanData['isAdvanced'] == true ||
          scanData['analysisSource'] != null ||
          (scanData['id'] != null &&
              (scanData['id'] as String).startsWith(scanIdPrefix)) ||
          (scanData['id'] != null &&
              (scanData['id'] as String)
                  .startsWith(ResultScreenConstants.advancedScanPrefix)),
    );
  }

  Future<bool> isScanAlreadySaved(String scanId) async {
    final existing = await _scanRepository.getScanById(scanId);
    return existing != null;
  }

  Future<Map<String, dynamic>> processScanData(
      Map<String, dynamic> scanData,
      String scanId,
      LeafAnalysisResult? leafAnalysis,
      String severity,
      List<String> remediation,
      ) async {
    final processedData = Map<String, dynamic>.from(scanData);

    final imageBase64 = await DataParsers.getImageBase64(
      scanData['imagePath'] as String?,
      scanData['imageBase64'] as String?,
    );

    if (imageBase64 != null) {
      processedData['imageBase64'] = imageBase64;
    }

    // Fix data types
    if (processedData['confidence'] is String) {
      if (leafAnalysis != null && !leafAnalysis.isLeaf) {
        processedData['confidence'] = leafAnalysis.confidence;
      } else {
        processedData['confidence'] =
            double.tryParse(processedData['confidence']) ?? 0.0;
      }
    }

    processedData['symptoms'] = DataParsers.parseStringToList(processedData['symptoms']);
    processedData['remediation'] =
    remediation.isNotEmpty ? remediation : DataParsers.parseStringToList(processedData['remediation']);
    processedData['precautions'] = DataParsers.parseStringToList(processedData['precautions']);
    processedData['severity'] = severity;
    processedData['id'] = scanId;

    return processedData;
  }

  String generateScanId(Map<String, dynamic> scanData) {
    return DataParsers.generateScanId(scanData, scanIdPrefix);
  }

  Future<void> saveScan(Map<String, dynamic> processedData, String? imagePath) async {
    await _scanRepository.saveOnDeviceScan(
      scanData: processedData,
      imagePath: imagePath,
    );
  }
}