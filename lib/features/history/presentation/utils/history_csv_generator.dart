// lib/features/history/utils/history_csv_generator.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class HistoryCsvGenerator {
  static Future<File> generateHistoryCsv({
    required List<Map<String, dynamic>> onDeviceScans,
    required List<Map<String, dynamic>> advancedScans,
  }) async {
    List<List<dynamic>> rows = [];

    // Headers
    rows.add([
      'Scan Type',
      'Number',
      'Plant Name',
      'Disease/Diagnosis',
      'Severity',
      'Confidence',
      'Scan Date',
      'Status',
      'Treatments',
      'Symptoms',
    ]);

    // On-Device Scans
    for (var i = 0; i < onDeviceScans.length; i++) {
      final scan = onDeviceScans[i];
      rows.add(_scanToRow('On-Device', i + 1, scan));
    }

    // Advanced Scans
    for (var i = 0; i < advancedScans.length; i++) {
      final scan = advancedScans[i];
      rows.add(_scanToRow('Advanced', i + 1, scan));
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'AgriGuard_History_$timestamp.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    print('History CSV saved: ${file.path}');
    return file;
  }

  static List<dynamic> _scanToRow(
      String scanType,
      int number,
      Map<String, dynamic> scan,
      ) {
    final plantName = scan['plantName']?.toString() ?? 'Unknown';
    final disease = scan['diseaseName']?.toString() ??
        scan['diagnosis']?.toString() ?? 'Unknown';
    final severity = scan['severity']?.toString() ?? 'N/A';
    final confidence = scan['confidence']?.toString() ?? 'N/A';
    final date = _parseDate(scan['scanDate'] ?? scan['timestamp']);
    final isHealthy = disease.toLowerCase().contains('healthy');
    final status = isHealthy ? 'Healthy' : 'Diseased';

    final treatments = scan['treatments'] is List
        ? (scan['treatments'] as List).join('; ')
        : scan['treatment']?.toString() ?? 'N/A';

    final symptoms = scan['symptoms'] is List
        ? (scan['symptoms'] as List).join('; ')
        : 'N/A';

    return [
      scanType,
      number,
      plantName,
      disease,
      severity,
      confidence,
      date,
      status,
      treatments,
      symptoms,
    ];
  }

  static String _parseDate(dynamic timestamp) {
    try {
      DateTime? dt;
      if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dt = DateTime.tryParse(timestamp);
      } else if (timestamp is DateTime) {
        dt = timestamp;
      }

      if (dt != null) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      }
    } catch (e) {
      print('Date parse error: $e');
    }
    return 'Unknown';
  }
}