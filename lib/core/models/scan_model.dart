import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

enum ScanType {
  onDevice,
  advanced,
}

enum AnalysisSource {
  onDeviceML('On-Device ML'),
  groq('Groq AI'),
  plantId('Plant.id'),
  huggingface('Hugging Face');

  final String displayName;
  const AnalysisSource(this.displayName);
}

class ScanModel {
  final String? id;
  final String userId;
  final ScanType scanType;
  final AnalysisSource analysisSource;

  // Plant info
  final String plantName;
  final String scientificName;

  // Disease info
  final String diseaseName;
  final String severity;
  final int confidence;

  // Treatment info
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> precautions;

  // Image info
  final String? imagePath;
  final String? imageUrl;
  final String? imageBase64;

  // Timestamps
  final DateTime scanDate;
  final DateTime createdAt;

  // Raw data
  final Map<String, dynamic> rawData;
  final Map<String, dynamic>? advancedData;

  // Status
  final bool isSynced;

  ScanModel({
    this.id,
    required this.userId,
    required this.scanType,
    required this.analysisSource,
    required this.plantName,
    required this.scientificName,
    required this.diseaseName,
    required this.severity,
    required this.confidence,
    required this.symptoms,
    required this.treatments,
    required this.precautions,
    this.imagePath,
    this.imageUrl,
    this.imageBase64,
    required this.scanDate,
    required this.createdAt,
    required this.rawData,
    this.advancedData,
    this.isSynced = false,
  });

  bool get isAdvanced => scanType == ScanType.advanced;

  // Update the ScanModel constructors to handle confidence properly:

  factory ScanModel.fromOnDeviceScan({
    required String userId,
    required Map<String, dynamic> scanData,
    String? imagePath,
    String? imageUrl,
  }) {
    // Safely parse confidence
    int confidence = 0;
    final confidenceValue = scanData['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is num) {
        confidence = confidenceValue.toInt();
      } else if (confidenceValue is String) {
        // Try to parse string to int
        final parsed = double.tryParse(confidenceValue);
        confidence = parsed?.toInt() ?? 0;
      }
    }

    // SAFELY parse symptoms - handle both String and List
    List<String> symptomsList = [];
    final symptomsValue = scanData['symptoms'];
    if (symptomsValue != null) {
      if (symptomsValue is List) {
        symptomsList = List<String>.from(symptomsValue.map((item) => item.toString()));
      } else if (symptomsValue is String) {
        if (symptomsValue.contains('[')) {
          // Try to parse JSON array
          try {
            final parsed = jsonDecode(symptomsValue) as List;
            symptomsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            // If JSON parsing fails, split by commas or newlines
            symptomsList = symptomsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        } else {
          // Split by commas or newlines
          symptomsList = symptomsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }
    }

    // SAFELY parse treatments/remediation
    List<String> treatmentsList = [];
    final remediationValue = scanData['remediation'];
    final treatmentValue = scanData['treatment'];

    final treatmentsSource = remediationValue ?? treatmentValue;
    if (treatmentsSource != null) {
      if (treatmentsSource is List) {
        treatmentsList = List<String>.from(treatmentsSource.map((item) => item.toString()));
      } else if (treatmentsSource is String) {
        if (treatmentsSource.contains('[')) {
          try {
            final parsed = jsonDecode(treatmentsSource) as List;
            treatmentsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            treatmentsList = treatmentsSource.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        } else {
          treatmentsList = treatmentsSource.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }
    }

    // SAFELY parse precautions
    List<String> precautionsList = [];
    final precautionsValue = scanData['precautions'];
    if (precautionsValue != null) {
      if (precautionsValue is List) {
        precautionsList = List<String>.from(precautionsValue.map((item) => item.toString()));
      } else if (precautionsValue is String) {
        if (precautionsValue.contains('[')) {
          try {
            final parsed = jsonDecode(precautionsValue) as List;
            precautionsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            precautionsList = precautionsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        } else {
          precautionsList = precautionsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }
    }

    return ScanModel(
      userId: userId,
      scanType: ScanType.onDevice,
      analysisSource: AnalysisSource.onDeviceML,
      plantName: scanData['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: scanData['scientificName']?.toString() ?? '',
      diseaseName: scanData['diseaseName']?.toString() ?? 'Healthy',
      severity: scanData['severity']?.toString() ?? 'Medium',
      confidence: confidence,
      symptoms: symptomsList,
      treatments: treatmentsList,
      precautions: precautionsList,
      imagePath: imagePath,
      imageUrl: imageUrl,
      scanDate: DateTime.now(),
      createdAt: DateTime.now(),
      rawData: scanData,
    );
  }

  factory ScanModel.fromGroqScan({
    required String userId,
    required Map<String, dynamic> analysisResult,
    String? imagePath,
    String? imageUrl,
  }) {
    final data = analysisResult['data'] as Map<String, dynamic>? ?? {};

    // Safely parse confidence
    int confidence = 0;
    final confidenceValue = data['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is num) {
        confidence = confidenceValue.toInt();
      } else if (confidenceValue is String) {
        final parsed = double.tryParse(confidenceValue);
        confidence = parsed?.toInt() ?? 0;
      }
    }

    // SAFELY parse symptoms
    List<String> symptomsList = [];
    final symptomsValue = data['symptoms'];
    if (symptomsValue != null) {
      if (symptomsValue is List) {
        symptomsList = List<String>.from(symptomsValue.map((item) => item.toString()));
      } else if (symptomsValue is String) {
        symptomsList = symptomsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    // SAFELY parse treatments
    List<String> treatmentsList = [];
    final treatmentsValue = data['remediation'];
    if (treatmentsValue != null) {
      if (treatmentsValue is List) {
        treatmentsList = List<String>.from(treatmentsValue.map((item) => item.toString()));
      } else if (treatmentsValue is String) {
        treatmentsList = treatmentsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    // SAFELY parse precautions
    List<String> precautionsList = [];
    final precautionsValue = data['precautions'];
    if (precautionsValue != null) {
      if (precautionsValue is List) {
        precautionsList = List<String>.from(precautionsValue.map((item) => item.toString()));
      } else if (precautionsValue is String) {
        precautionsList = precautionsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.groq,
      plantName: data['plant']?.toString() ??
          data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ??
          data['diseaseName']?.toString() ?? 'Healthy',
      severity: data['severity']?.toString() ?? 'Medium',
      confidence: confidence,
      symptoms: symptomsList,
      treatments: treatmentsList,
      precautions: precautionsList,
      imagePath: imagePath,
      imageUrl: imageUrl,
      scanDate: DateTime.now(),
      createdAt: DateTime.now(),
      rawData: analysisResult,
      advancedData: data,
    );
  }

  factory ScanModel.fromPlantIdScan({
    required String userId,
    required Map<String, dynamic> analysisResult,
    String? imagePath,
    String? imageUrl,
  }) {
    final data = analysisResult['data'] as Map<String, dynamic>? ?? {};

    // Safely parse confidence
    int confidence = 0;
    final confidenceValue = data['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is num) {
        confidence = confidenceValue.toInt();
      } else if (confidenceValue is String) {
        final parsed = double.tryParse(confidenceValue);
        confidence = parsed?.toInt() ?? 0;
      }
    }

    // SAFELY parse symptoms
    List<String> symptomsList = [];
    final symptomsValue = data['symptoms'];
    if (symptomsValue != null) {
      if (symptomsValue is List) {
        symptomsList = List<String>.from(symptomsValue.map((item) => item.toString()));
      } else if (symptomsValue is String) {
        if (symptomsValue.contains('[')) {
          // Try to parse JSON array
          try {
            final parsed = jsonDecode(symptomsValue) as List;
            symptomsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            // If JSON parsing fails, split by commas or newlines
            symptomsList = symptomsValue.split(RegExp(r'[,;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else {
          // Split by commas or newlines
          symptomsList = symptomsValue.split(RegExp(r'[,;\n]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }

    // SAFELY parse treatments/remediation
    List<String> treatmentsList = [];
    final treatmentsValue = data['remediation'];
    if (treatmentsValue != null) {
      if (treatmentsValue is List) {
        treatmentsList = List<String>.from(treatmentsValue.map((item) => item.toString()));
      } else if (treatmentsValue is String) {
        if (treatmentsValue.contains('[')) {
          try {
            final parsed = jsonDecode(treatmentsValue) as List;
            treatmentsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            treatmentsList = treatmentsValue.split(RegExp(r'[,;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else {
          treatmentsList = treatmentsValue.split(RegExp(r'[,;\n]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }

    // SAFELY parse precautions
    List<String> precautionsList = [];
    final precautionsValue = data['precautions'];
    if (precautionsValue != null) {
      if (precautionsValue is List) {
        precautionsList = List<String>.from(precautionsValue.map((item) => item.toString()));
      } else if (precautionsValue is String) {
        if (precautionsValue.contains('[')) {
          try {
            final parsed = jsonDecode(precautionsValue) as List;
            precautionsList = List<String>.from(parsed.map((item) => item.toString()));
          } catch (e) {
            precautionsList = precautionsValue.split(RegExp(r'[,;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else {
          precautionsList = precautionsValue.split(RegExp(r'[,;\n]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.plantId,
      plantName: data['plant']?.toString() ??
          data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ??
          data['diseaseName']?.toString() ?? 'Healthy',
      severity: data['severity']?.toString() ?? 'Medium',
      confidence: confidence,
      symptoms: symptomsList,
      treatments: treatmentsList,
      precautions: precautionsList,
      imagePath: imagePath,
      imageUrl: imageUrl,
      scanDate: DateTime.now(),
      createdAt: DateTime.now(),
      rawData: analysisResult,
      advancedData: data,
    );
  }

  factory ScanModel.fromHuggingFaceScan({
    required String userId,
    required Map<String, dynamic> analysisResult,
    String? imagePath,
    String? imageUrl,
  }) {
    // Same schema shape as other advanced scans: analysisResult['data']
    final data = analysisResult['data'] as Map<String, dynamic>? ?? {};

    int confidence = 0;
    final confidenceValue = data['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is num) {
        confidence = confidenceValue.toInt();
      } else if (confidenceValue is String) {
        final parsed = double.tryParse(confidenceValue);
        confidence = parsed?.toInt() ?? 0;
      }
    }

    List<String> symptomsList = [];
    final symptomsValue = data['symptoms'];
    if (symptomsValue != null) {
      if (symptomsValue is List) {
        symptomsList = List<String>.from(symptomsValue.map((item) => item.toString()));
      } else if (symptomsValue is String) {
        symptomsList = symptomsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    List<String> treatmentsList = [];
    final treatmentsValue = data['remediation'];
    if (treatmentsValue != null) {
      if (treatmentsValue is List) {
        treatmentsList = List<String>.from(treatmentsValue.map((item) => item.toString()));
      } else if (treatmentsValue is String) {
        treatmentsList = treatmentsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    List<String> precautionsList = [];
    final precautionsValue = data['precautions'];
    if (precautionsValue != null) {
      if (precautionsValue is List) {
        precautionsList = List<String>.from(precautionsValue.map((item) => item.toString()));
      } else if (precautionsValue is String) {
        precautionsList = precautionsValue.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.huggingface,
      plantName: data['plant']?.toString() ??
          data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ??
          data['diseaseName']?.toString() ?? 'Healthy',
      severity: data['severity']?.toString() ?? 'Medium',
      confidence: confidence,
      symptoms: symptomsList,
      treatments: treatmentsList,
      precautions: precautionsList,
      imagePath: imagePath,
      imageUrl: imageUrl,
      scanDate: DateTime.now(),
      createdAt: DateTime.now(),
      rawData: analysisResult,
      advancedData: data,
    );
  }

  ScanModel copyWith({
    String? id,
    String? userId,
    ScanType? scanType,
    AnalysisSource? analysisSource,
    String? plantName,
    String? scientificName,
    String? diseaseName,
    String? severity,
    int? confidence,
    List<String>? symptoms,
    List<String>? treatments,
    List<String>? precautions,
    String? imagePath,
    String? imageUrl,
    String? imageBase64,
    DateTime? scanDate,
    DateTime? createdAt,
    Map<String, dynamic>? rawData,
    Map<String, dynamic>? advancedData,
    bool? isSynced,
  }) {
    return ScanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scanType: scanType ?? this.scanType,
      analysisSource: analysisSource ?? this.analysisSource,
      plantName: plantName ?? this.plantName,
      scientificName: scientificName ?? this.scientificName,
      diseaseName: diseaseName ?? this.diseaseName,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      symptoms: symptoms ?? this.symptoms,
      treatments: treatments ?? this.treatments,
      precautions: precautions ?? this.precautions,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      scanDate: scanDate ?? this.scanDate,
      createdAt: createdAt ?? this.createdAt,
      rawData: rawData ?? this.rawData,
      advancedData: advancedData ?? this.advancedData,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'scanType': scanType.name,
      'analysisSource': analysisSource.name,
      'plantName': plantName,
      'scientificName': scientificName,
      'diseaseName': diseaseName,
      'severity': severity,
      'confidence': confidence,
      'symptoms': symptoms,
      'treatments': treatments,
      'precautions': precautions,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'scanDate': Timestamp.fromDate(scanDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'rawData': rawData,
      'advancedData': advancedData,
      'isSynced': isSynced,
      'isAdvanced': isAdvanced,
      'serverCreatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ScanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ScanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      scanType: ScanType.values.firstWhere(
            (e) => e.name == data['scanType'],
        orElse: () => ScanType.onDevice,
      ),
      analysisSource: AnalysisSource.values.firstWhere(
            (e) => e.name == data['analysisSource'],
        // Legacy support: old saved scans may contain prior source strings
        orElse: () {
          final src = data['analysisSource']?.toString().toLowerCase();
          if (src == 'gemini') return AnalysisSource.groq;
          if (src == 'huggingface' || src == 'hugging face' || src == 'hf') {
            return AnalysisSource.huggingface;
          }
          return AnalysisSource.onDeviceML;
        },
      ),
      plantName: data['plantName'] ?? '',
      scientificName: data['scientificName'] ?? '',
      diseaseName: data['diseaseName'] ?? '',
      severity: data['severity'] ?? '',
      confidence: (data['confidence'] as num?)?.toInt() ?? 0,
      symptoms: List<String>.from(data['symptoms'] ?? []),
      treatments: List<String>.from(data['treatments'] ?? []),
      precautions: List<String>.from(data['precautions'] ?? []),
      imagePath: data['imagePath'],
      imageUrl: data['imageUrl'],
      imageBase64: data['imageBase64'],
      scanDate: (data['scanDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rawData: Map<String, dynamic>.from(data['rawData'] ?? {}),
      advancedData: data['advancedData'] != null
          ? Map<String, dynamic>.from(data['advancedData'] as Map)
          : null,
      isSynced: data['isSynced'] ?? false,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'scanType': scanType.name,
      'analysisSource': analysisSource.name,
      'plantName': plantName,
      'scientificName': scientificName,
      'diseaseName': diseaseName,
      'severity': severity,
      'confidence': confidence,
      'symptoms': symptoms.join('|||'),
      'treatments': treatments.join('|||'),
      'precautions': precautions.join('|||'),
      'imagePath': imagePath ?? '',
      'imageUrl': imageUrl ?? '',
      'imageBase64': imageBase64 ?? '',
      'scanDate': scanDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'rawData': jsonEncode(rawData),
      'advancedData': advancedData != null ? jsonEncode(advancedData) : '',
      'isSynced': isSynced ? 1 : 0,
      'isAdvanced': isAdvanced ? 1 : 0,
    };
  }
  factory ScanModel.fromSqliteMap(Map<String, dynamic> map) {
    // Safely parse confidence from SQLite
    int confidence = 0;
    final confidenceValue = map['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is int) {
        confidence = confidenceValue;
      } else if (confidenceValue is num) {
        confidence = confidenceValue.toInt();
      } else if (confidenceValue is String) {
        final parsed = int.tryParse(confidenceValue);
        confidence = parsed ?? 0;
      }
    }

    // Safely parse lists from SQLite
    List<String> parseList(String? listString) {
      if (listString == null || listString.isEmpty) return [];
      return listString.split('|||').where((item) => item.isNotEmpty).toList();
    }

    return ScanModel(
      id: map['id']?.toString(),
      userId: map['userId'] ?? '',
      scanType: ScanType.values.firstWhere(
            (e) => e.name == map['scanType'],
        orElse: () => ScanType.onDevice,
      ),
      analysisSource: AnalysisSource.values.firstWhere(
            (e) => e.name == map['analysisSource'],
        // Legacy support: old saved scans may contain prior source strings
        orElse: () {
          final src = map['analysisSource']?.toString().toLowerCase();
          if (src == 'gemini') return AnalysisSource.groq;
          if (src == 'huggingface' || src == 'hugging face' || src == 'hf') {
            return AnalysisSource.huggingface;
          }
          return AnalysisSource.onDeviceML;
        },
      ),
      plantName: map['plantName'] ?? '',
      scientificName: map['scientificName'] ?? '',
      diseaseName: map['diseaseName'] ?? '',
      severity: map['severity'] ?? '',
      confidence: confidence,
      symptoms: parseList(map['symptoms'] as String?),
      treatments: parseList(map['treatments'] as String?),
      precautions: parseList(map['precautions'] as String?),
      imagePath: map['imagePath']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      imageBase64: map['imageBase64']?.toString(),
      scanDate: DateTime.parse(map['scanDate'] ?? DateTime.now().toIso8601String()),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.parse(map['scanDate'] ?? DateTime.now().toIso8601String()),
      rawData: jsonDecode(map['rawData'] ?? '{}'),
      advancedData: map['advancedData'] != null &&
          (map['advancedData'] as String).isNotEmpty
          ? jsonDecode(map['advancedData'] as String)
          : null,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }  Map<String, dynamic> toHistoryMap() {
    return {
      'id': id,
      'diagnosis': diseaseName,
      'severity': severity,
      'confidence': confidence.toString(),  // Keep as string for compatibility
      'plantName': plantName,
      'scientificName': scientificName,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'scanType': scanType.name,
      'analysisSource': analysisSource.name,
      'isAdvanced': isAdvanced,
      'advancedData': advancedData,
      'symptoms': symptoms,
      'treatments': treatments,
      'precautions': precautions,
      'scanDate': scanDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'rawData': rawData,
      // IMPORTANT: Add all fields needed by ResultsScreen
      'diseaseName': diseaseName,
      'remediation': treatments,
      'treatment': treatments,
      'cause': 'Saved scan from history',
      'isFromHistory': true, // This flag prevents auto-save
    };
  }  @override
  String toString() {
    return 'ScanModel(id: $id, plant: $plantName, disease: $diseaseName, isAdvanced: $isAdvanced, createdAt: $createdAt)';
  }
}