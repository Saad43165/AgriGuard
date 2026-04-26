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
  roboflow('Roboflow');

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

  // -----------------------------
  // Helpers
  // -----------------------------
  static int _parseConfidence(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final d = double.tryParse(value.replaceAll('%', '').trim());
      return d?.toInt() ?? 0;
    }
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return <String>[];

      // If string looks like JSON array -> try decode
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final parsed = jsonDecode(s);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).where((x) => x.trim().isNotEmpty).toList();
          }
        } catch (_) {}
      }

      // fallback split
      return s
          .split(RegExp(r'[,;\n]'))
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  // -----------------------------
  // Constructors
  // -----------------------------
  factory ScanModel.fromOnDeviceScan({
    required String userId,
    required Map<String, dynamic> scanData,
    String? imagePath,
    String? imageUrl,
  }) {
    final confidence = _parseConfidence(scanData['confidence']);
    final symptomsList = _parseStringList(scanData['symptoms']);

    final remediationValue = scanData['remediation'];
    final treatmentValue = scanData['treatment'];
    final treatmentsList = _parseStringList(remediationValue ?? treatmentValue);

    final precautionsList = _parseStringList(scanData['precautions']);

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

    final confidence = _parseConfidence(data['confidence']);
    final symptomsList = _parseStringList(data['symptoms']);
    final treatmentsList = _parseStringList(data['remediation']);
    final precautionsList = _parseStringList(data['precautions']);

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.groq,
      plantName: data['plant']?.toString() ?? data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ?? data['diseaseName']?.toString() ?? 'Healthy',
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

    final confidence = _parseConfidence(data['confidence']);
    final symptomsList = _parseStringList(data['symptoms']);
    final treatmentsList = _parseStringList(data['remediation']);
    final precautionsList = _parseStringList(data['precautions']);

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.plantId,
      plantName: data['plant']?.toString() ?? data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ?? data['diseaseName']?.toString() ?? 'Healthy',
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

  /// Replaces the old HuggingFace constructor.
  factory ScanModel.fromRoboflowScan({
    required String userId,
    required Map<String, dynamic> analysisResult,
    String? imagePath,
    String? imageUrl,
  }) {
    final data = analysisResult['data'] as Map<String, dynamic>? ?? {};

    final confidence = _parseConfidence(data['confidence']);
    final symptomsList = _parseStringList(data['symptoms']);
    final treatmentsList = _parseStringList(data['remediation']);
    final precautionsList = _parseStringList(data['precautions']);

    return ScanModel(
      userId: userId,
      scanType: ScanType.advanced,
      analysisSource: AnalysisSource.roboflow,
      plantName: data['plant']?.toString() ?? data['plantName']?.toString() ?? 'Unknown Plant',
      scientificName: data['scientificName']?.toString() ?? '',
      diseaseName: data['disease']?.toString() ?? data['diseaseName']?.toString() ?? 'Healthy',
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

  // -----------------------------
  // Copy / Serialization
  // -----------------------------
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

    AnalysisSource resolveSource() {
      // Normal path if enum name exists
      final raw = data['analysisSource'];
      if (raw == null) return AnalysisSource.onDeviceML;

      final normalized = raw.toString().toLowerCase().trim();

      // Legacy mappings
      if (normalized == 'gemini') return AnalysisSource.groq;
      if (normalized == 'huggingface' || normalized == 'hugging face' || normalized == 'hf') {
        return AnalysisSource.roboflow; // migrate legacy hf -> roboflow
      }
      if (normalized == 'roboflow') return AnalysisSource.roboflow;
      if (normalized == 'plantid' || normalized == 'plant.id') return AnalysisSource.plantId;
      if (normalized == 'groq') return AnalysisSource.groq;
      if (normalized == 'ondeviceml' || normalized == 'on_device_ml') return AnalysisSource.onDeviceML;

      // Try enum name match (for safety)
      return AnalysisSource.values.firstWhere(
            (e) => e.name.toLowerCase() == normalized,
        orElse: () => AnalysisSource.onDeviceML,
      );
    }

    return ScanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      scanType: ScanType.values.firstWhere(
            (e) => e.name == data['scanType'],
        orElse: () => ScanType.onDevice,
      ),
      analysisSource: resolveSource(),
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
    int confidence = 0;
    final confidenceValue = map['confidence'];
    if (confidenceValue != null) {
      if (confidenceValue is int) confidence = confidenceValue;
      if (confidenceValue is num) confidence = confidenceValue.toInt();
      if (confidenceValue is String) confidence = int.tryParse(confidenceValue) ?? 0;
    }

    List<String> parseList(String? listString) {
      if (listString == null || listString.isEmpty) return [];
      return listString.split('|||').where((item) => item.isNotEmpty).toList();
    }

    AnalysisSource resolveSource() {
      final raw = map['analysisSource'];
      if (raw == null) return AnalysisSource.onDeviceML;
      final normalized = raw.toString().toLowerCase().trim();

      // Legacy mappings
      if (normalized == 'gemini') return AnalysisSource.groq;
      if (normalized == 'huggingface' || normalized == 'hugging face' || normalized == 'hf') {
        return AnalysisSource.roboflow; // migrate legacy hf -> roboflow
      }
      if (normalized == 'roboflow') return AnalysisSource.roboflow;
      if (normalized == 'plantid' || normalized == 'plant.id') return AnalysisSource.plantId;
      if (normalized == 'groq') return AnalysisSource.groq;

      return AnalysisSource.values.firstWhere(
            (e) => e.name.toLowerCase() == normalized,
        orElse: () => AnalysisSource.onDeviceML,
      );
    }

    return ScanModel(
      id: map['id']?.toString(),
      userId: map['userId'] ?? '',
      scanType: ScanType.values.firstWhere(
            (e) => e.name == map['scanType'],
        orElse: () => ScanType.onDevice,
      ),
      analysisSource: resolveSource(),
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
      advancedData: map['advancedData'] != null && (map['advancedData'] as String).isNotEmpty
          ? jsonDecode(map['advancedData'] as String)
          : null,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toHistoryMap() {
    return {
      'id': id,
      'diagnosis': diseaseName,
      'severity': severity,
      'confidence': confidence.toString(),
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
      'diseaseName': diseaseName,
      'remediation': treatments,
      'treatment': treatments,
      'cause': 'Saved scan from history',
      'isFromHistory': true,
    };
  }

  @override
  String toString() {
    return 'ScanModel(id: $id, plant: $plantName, disease: $diseaseName, isAdvanced: $isAdvanced, createdAt: $createdAt)';
  }
}