// lib/features/ResultScreen/presentation/results_screen.dart
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/next_steps_card.dart' show NextStepsCard;
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/result_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import 'components/analysis_details_Card.dart';
import 'components/diagnosis_card.dart';
import 'components/diagnosis_result.dart';
import 'components/disease_cause_card.dart';
import 'components/floating_advance_search_banner.dart';
import 'components/recommentations_card.dart';
import 'components/scanned_image_Section.dart';
import '../../../../core/repositories/scan_repository.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ResultsScreen({super.key, required this.scanData});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  bool _showAdvancedSearchBanner = false;

  // JSON data
  Map<String, dynamic> _diseaseCauses = {};
  Map<String, dynamic> _diseaseMapping = {};
  bool _jsonLoaded = false;
  List<String> _diseaseCausesList = [];

  // Scan Repository
  late final ScanRepository _scanRepository;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scanRepository = ScanRepository();
    _loadJsonData();
    _scheduleAdvancedSearchBanner();

    // Check and save scan after short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSaveScan();
    });
  }

  Future<void> _loadJsonData() async {
    try {
      debugPrint('📚 Loading JSON data...');

      // Load disease causes JSON
      final causesJson = await rootBundle.loadString('assets/data/disease_causes.json');
      _diseaseCauses = json.decode(causesJson);

      // Load disease mapping JSON
      final mappingJson = await rootBundle.loadString('assets/data/disease_mapping.json');
      _diseaseMapping = json.decode(mappingJson);

      // Extract causes for current disease
      _extractDiseaseCauses();

      setState(() {
        _jsonLoaded = true;
      });

    } catch (e) {
      debugPrint('❌ Error loading JSON data: $e');
      _diseaseCauses = {};
      _diseaseMapping = {};
      _diseaseCausesList = [];
      _jsonLoaded = true;
    }
  }

  Future<void> _checkAndSaveScan() async {
    // CRITICAL: Check all possible flags that indicate this is from history
    final isFromHistory = widget.scanData['isFromHistory'] == true ||
        widget.scanData['skipSave'] == true ||
        widget.scanData['databaseId'] != null;

    if (isFromHistory) {
      debugPrint('📂 Opening saved scan from history - skipping auto-save');
      setState(() => _isAlreadySaved = true);
      return;
    }

    // Check if this scan has already been processed in this session
    if (_isAlreadySaved || _isSaving) {
      debugPrint('✅ Scan already saved or being saved in this session');
      return;
    }

    // Check if this is an advanced scan that should be saved elsewhere
    if (widget.scanData['isAdvanced'] == true ||
        widget.scanData['analysisSource'] != null) {
      debugPrint('🔄 This is an advanced scan - should be saved in AdvancedResultsScreen');
      setState(() => _isAlreadySaved = true);
      return;
    }

    // If scan already has an ID, it's probably already saved
    if (widget.scanData['id'] != null &&
        ((widget.scanData['id'] as String).startsWith('ondevice_') ||
            (widget.scanData['id'] as String).startsWith('advanced_'))) {
      debugPrint('✅ Scan already has a database ID, skipping save');
      setState(() => _isAlreadySaved = true);
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Generate scan ID using original image path if available
      final scanId = _generateScanId();

      // Use original ID if it exists (for proper duplicate detection)
      final originalId = widget.scanData['originalId'] as String?;
      final finalScanId = originalId ?? scanId;

      // Check if scan already exists in database
      final existingScan = await _scanRepository.getScanById(finalScanId);
      if (existingScan != null) {
        debugPrint('✅ On-device scan already exists in database, skipping save');
        setState(() {
          _isAlreadySaved = true;
          _isSaving = false;
        });
        return;
      }

      // Prepare image base64
      String? imageBase64 = widget.scanData['imageBase64'] as String?;
      final imagePath = widget.scanData['imagePath'] as String?;

      if (imageBase64 == null && imagePath != null) {
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

      // Ensure data is in correct format for ScanModel
      final scanDataWithFix = Map<String, dynamic>.from(widget.scanData);

      // Convert confidence to number if it's a string
      if (scanDataWithFix['confidence'] is String) {
        final confidenceStr = scanDataWithFix['confidence'] as String;
        final confidenceNum = double.tryParse(confidenceStr) ?? 0.0;
        scanDataWithFix['confidence'] = confidenceNum;
      }

      // Ensure symptoms is a List
      if (scanDataWithFix['symptoms'] is String) {
        final symptomsStr = scanDataWithFix['symptoms'] as String;
        scanDataWithFix['symptoms'] = symptomsStr.split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (scanDataWithFix['symptoms'] == null) {
        scanDataWithFix['symptoms'] = [];
      }

      // Ensure treatment/remediation is a List
      if (scanDataWithFix['remediation'] is String) {
        final remediationStr = scanDataWithFix['remediation'] as String;
        scanDataWithFix['remediation'] = remediationStr.split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (scanDataWithFix['treatment'] is String) {
        final treatmentStr = scanDataWithFix['treatment'] as String;
        scanDataWithFix['treatment'] = treatmentStr.split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (scanDataWithFix['remediation'] == null && scanDataWithFix['treatment'] == null) {
        scanDataWithFix['remediation'] = [];
      }

      // Ensure precautions is a List
      if (scanDataWithFix['precautions'] is String) {
        final precautionsStr = scanDataWithFix['precautions'] as String;
        scanDataWithFix['precautions'] = precautionsStr.split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (scanDataWithFix['precautions'] == null) {
        scanDataWithFix['precautions'] = [];
      }

      // Add image base64 to scan data
      scanDataWithFix['imageBase64'] = imageBase64;
      // Use the generated ID
      scanDataWithFix['id'] = finalScanId;

      debugPrint('📊 Prepared scan data for saving - symptoms: ${scanDataWithFix['symptoms']}, treatments: ${scanDataWithFix['remediation'] ?? scanDataWithFix['treatment']}');

      // Save the scan
      final savedScan = await _scanRepository.saveOnDeviceScan(
        scanData: scanDataWithFix,
        imagePath: imagePath,
      );

      debugPrint('✅ On-device scan auto-saved: ${savedScan.id}');

      setState(() {
        _isAlreadySaved = true;
        _isSaving = false;
      });

    } catch (e, stackTrace) {
      debugPrint('❌ Auto-save error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isSaving = false);

      // Don't show error for duplicate scans
      if (!e.toString().toLowerCase().contains('duplicate') &&
          !e.toString().toLowerCase().contains('already exists') &&
          !e.toString().contains('String') &&
          !e.toString().contains('num') &&
          !e.toString().contains('Iterable')) {
        _showSaveError();
      }
    }
  }
// Update the ID generation to be more unique
  String _generateScanId() {
    final dataHash = jsonEncode({
      'plant': widget.scanData['plantName'],
      'disease': widget.scanData['diseaseName'],
      'confidence': widget.scanData['confidence'],
      'image': widget.scanData['imagePath']?.hashCode ?? 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).hashCode.abs();

    return 'ondevice_${dataHash}_${DateTime.now().millisecondsSinceEpoch}';
  }
  void _showSaveError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Failed to save scan'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  void _extractDiseaseCauses() {
    try {
      final rawLabel = widget.scanData['rawLabel']?.toString();
      final diseaseName = widget.scanData['diseaseName']?.toString();
      final plantName = widget.scanData['plantName']?.toString();

      // If analysis failed
      if (diseaseName == null ||
          diseaseName.toLowerCase().contains('unable to determine') ||
          diseaseName.toLowerCase().contains('image quality issue') ||
          diseaseName.toLowerCase().contains('analysis required')) {
        _diseaseCausesList = [
          'Analysis could not be completed successfully',
          'This may be due to poor image quality or unclear symptoms',
          'Please try again with a clearer photo'
        ];
        return;
      }

      // If plant not identified
      if (plantName == null ||
          plantName.toLowerCase().contains('unknown') ||
          plantName.toLowerCase().contains('unable to determine')) {
        _diseaseCausesList = [
          'Plant species could not be identified',
          'Specific disease causes require plant identification',
          'For accurate diagnosis, please ensure:',
          '• Clear photo of the whole plant',
          '• Good lighting conditions',
          '• Focus on affected leaves'
        ];
        return;
      }

      // If plant is healthy
      final isHealthy = diseaseName.toLowerCase() == 'healthy' ||
          diseaseName.toLowerCase().contains('healthy') ||
          (widget.scanData['isHealthy'] as bool? ?? false);

      if (isHealthy) {
        _diseaseCausesList = [
          'Plant appears to be in good health',
          'No visible signs of disease or stress',
          'Maintaining current care practices is recommended'
        ];
        return;
      }

      // If low confidence
      final confidence = double.tryParse(widget.scanData['confidence']?.toString() ?? '0') ?? 0;
      if (confidence < 30.0) {
        _diseaseCausesList = [
          'Low confidence in disease identification',
          'Possible causes could include:',
          '• Environmental stress factors',
          '• Mild pathogen infection',
          '• Natural leaf variations',
          'Consult an expert for accurate diagnosis'
        ];
        return;
      }

      // Try to find disease in JSON
      String? diseaseKey;

      // Method 1: Direct match with raw label
      if (rawLabel != null && _diseaseCauses.containsKey(rawLabel)) {
        diseaseKey = rawLabel;
      }
      // Method 2: Check in disease mapping
      else if (rawLabel != null && _diseaseMapping.containsKey(rawLabel)) {
        final displayName = _diseaseMapping[rawLabel]['display_name']?.toString();
        if (displayName != null) {
          final searchKey = _findDiseaseKeyByDisplayName(displayName);
          if (searchKey != null) {
            diseaseKey = searchKey;
          }
        }
      }
      // Method 3: Construct key
      else      final constructedKey = '${plantName.replaceAll(' ', '_')}___${diseaseName.replaceAll(' ', '_').toLowerCase()}';
      if (_diseaseCauses.containsKey(constructedKey)) {
        diseaseKey = constructedKey;
      }
    

      // Get causes from found key
      if (diseaseKey != null && _diseaseCauses.containsKey(diseaseKey)) {
        final diseaseData = _diseaseCauses[diseaseKey];
        if (diseaseData is Map && diseaseData.containsKey('causes')) {
          final causes = diseaseData['causes'];
          if (causes is List && causes.isNotEmpty) {
            _diseaseCausesList = List<String>.from(causes);
          }
        }
      }

      // If no specific causes found
      if (_diseaseCausesList.isEmpty) {
        _tryGeneralCauses(diseaseName);
      }

    } catch (e) {
      debugPrint('❌ Error extracting disease causes: $e');
      _diseaseCausesList = [
        'Error loading disease information',
        'Please try again or consult an expert'
      ];
    }
  }

  String? _findDiseaseKeyByDisplayName(String displayName) {
    try {
      if (displayName.contains(' - ')) {
        final parts = displayName.split(' - ');
        if (parts.length == 2) {
          final plant = parts[0].replaceAll(' ', '_');
          final disease = parts[1].replaceAll(' ', '_').toLowerCase();
          final key = '${plant}___$disease';

          if (_diseaseCauses.containsKey(key)) {
            return key;
          }

          if (disease == 'healthy') {
            final healthyKey = '${plant}___healthy';
            if (_diseaseCauses.containsKey(healthyKey)) {
              return healthyKey;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error finding disease by display name: $e');
    }
    return null;
  }

  void _tryGeneralCauses(String diseaseName) {
    try {
      final lowerDisease = diseaseName.toLowerCase();

      if (_diseaseCauses.containsKey('general_disease_causes')) {
        final generalCauses = _diseaseCauses['general_disease_causes'];
        if (generalCauses is Map) {
          if (lowerDisease.contains('spot') && generalCauses.containsKey('bacterial_spot')) {
            final causes = generalCauses['bacterial_spot']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
            }
          } else if (lowerDisease.contains('blight') && generalCauses.containsKey('blight')) {
            final causes = generalCauses['blight']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
            }
          } else if (lowerDisease.contains('rust') && generalCauses.containsKey('rust_disease')) {
            final causes = generalCauses['rust_disease']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
            }
          } else if (lowerDisease.contains('mildew') && generalCauses.containsKey('powdery_mildew')) {
            final causes = generalCauses['powdery_mildew']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error trying general causes: $e');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _scheduleAdvancedSearchBanner() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showAdvancedSearchBanner = true);
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() => _showAdvancedSearchBanner = false);
          }
        });
      }
    });
  }

  void _navigateToAdvancedSearch() {
    setState(() => _showAdvancedSearchBanner = false);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchScreen(
          originalScanData: widget.scanData,
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (_isSaving) return;
    HapticFeedback.lightImpact();

    final previousRoute = widget.scanData['previousRoute'] as String?;
    final fromCapture = widget.scanData['fromCapture'] as bool? ?? false;

    if (fromCapture) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.scan,
            (route) => false,
      );
    } else if (previousRoute != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        previousRoute,
            (route) => false,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnosisResult = _getDiagnosisResult();

    final String? imagePath = widget.scanData['imagePath'] as String?;
    final String? imageUrl = widget.scanData['imageUrl'] as String?;
    final String? imageBase64 = widget.scanData['imageBase64'] as String?;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarContent(
          title: 'Analysis Results',
          showBackButton: !_isSaving,
          onBackPressed: _handleBackNavigation,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? const [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
                Color(0xFF0F0F23),
              ]
                  : [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.8),
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(
                8,
                    (index) => FloatingOrb(
                  index: index,
                  maxWidth: MediaQuery.of(context).size.width,
                  fadeController: _fadeController,
                  scaleAnimation: _scaleAnimation,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Scanned Image
                      if (imagePath != null || imageUrl != null || imageBase64 != null)
                        Column(
                          children: [
                            _buildImageSection(imagePath, imageUrl, imageBase64, theme),
                            const SizedBox(height: 20),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildNoImagePlaceholder(theme),
                            const SizedBox(height: 20),
                          ],
                        ),

                      // 2. Diagnosis Card
                      DiagnosisCard(diagnosisResult: diagnosisResult),
                      const SizedBox(height: 20),

                      // 3. Analysis Details Card
                      AnalysisDetailsCard(scanData: widget.scanData),
                      const SizedBox(height: 20),

                      // 4. Disease Causes Card
                      if (_jsonLoaded)
                        DiseaseCausesCard(
                          causes: _diseaseCausesList,
                        ),
                      const SizedBox(height: 20),

                      // 5. Treatment Recommendations
                      RecommendationsCard(
                        recommendations: diagnosisResult.recommendations,
                      ),
                      const SizedBox(height: 20),

                      // 6. Next Steps
                      const NextStepsCard(),
                      const SizedBox(height: 20),

                      // 7. Advanced Search Button
                      _buildAdvancedSearchButton(theme),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              if (_showAdvancedSearchBanner)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FloatingAdvancedSearchBanner(
                    onTap: _navigateToAdvancedSearch,
                    onDismiss: () {
                      setState(() => _showAdvancedSearchBanner = false);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
      String? imagePath,
      String? imageUrl,
      String? imageBase64,
      ThemeData theme,
      ) {
    Widget imageWidget;

    // Try base64 first
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = _buildNoImagePlaceholder(theme);
      }
    }
    // Try local file
    else if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
          );
        } else {
          imageWidget = _buildNoImagePlaceholder(theme);
        }
      } catch (e) {
        imageWidget = _buildNoImagePlaceholder(theme);
      }
    }
    // Try network URL
    else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImagePlaceholder(theme);
        },
      );
    }
    // No image available
    else {
      imageWidget = _buildNoImagePlaceholder(theme);
    }

    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageWidget,
      ),
    );
  }

  Widget _buildNoImagePlaceholder(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No image available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSearchButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAdvancedSearch,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want deeper analysis?',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try Advanced AI Search with Gemini & Plant.id',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DiagnosisResult _getDiagnosisResult() {
    try {
      // Get plant name
      String plantName = widget.scanData['plantName']?.toString() ?? 'Unknown Plant';

      // Get disease information
      String diseaseName = widget.scanData['diseaseName']?.toString() ??
          widget.scanData['diagnosis']?.toString() ??
          'Healthy';

      // Check if disease name contains plant information
      String diseasePlantName = '';
      if (widget.scanData['rawLabel'] != null &&
          widget.scanData['rawLabel'].toString().contains('___')) {
        final parts = widget.scanData['rawLabel'].toString().split('___');
        if (parts.length >= 2) {
          diseasePlantName = parts[0].replaceAll('_', ' ').trim();
        }
      }

      // Resolve plant name conflict
      if (diseasePlantName.isNotEmpty &&
          diseasePlantName.toLowerCase() != plantName.toLowerCase() &&
          diseasePlantName != 'Unknown Plant') {
        if (diseaseName.toLowerCase() != 'healthy') {
          plantName = diseasePlantName;
        }
      }

      String confidence = widget.scanData['confidence']?.toString() ?? '0';
      String severity = widget.scanData['severity']?.toString() ?? 'Medium';

      // Determine if plant is healthy
      bool isHealthy = diseaseName.toLowerCase() == 'healthy' ||
          diseaseName.toLowerCase().contains('no disease');

      // Adjust severity for healthy plants
      if (isHealthy) {
        severity = 'None';
      }

      // Get recommendations
      List<String> recommendations = [];
      if (widget.scanData['remediation'] != null) {
        if (widget.scanData['remediation'] is List) {
          recommendations = List<String>.from(widget.scanData['remediation']);
        } else if (widget.scanData['remediation'] is String) {
          recommendations = widget.scanData['remediation'].toString().split('. ');
        }
      } else if (widget.scanData['treatment'] != null) {
        if (widget.scanData['treatment'] is List) {
          recommendations = List<String>.from(widget.scanData['treatment']);
        } else if (widget.scanData['treatment'] is String) {
          recommendations = widget.scanData['treatment'].toString().split('. ');
        }
      }

      // Add default recommendations if none provided
      if (recommendations.isEmpty) {
        if (isHealthy) {
          recommendations = [
            'Continue regular plant care',
            'Maintain proper watering schedule',
            'Ensure adequate sunlight exposure',
            'Monitor for any changes in plant health'
          ];
        } else {
          recommendations = [
            'Apply appropriate fungicide if fungal disease is suspected',
            'Remove and destroy infected plant parts',
            'Improve air circulation around the plant',
            'Consult with agricultural expert for precise treatment'
          ];
        }
      }

      // Create DiagnosisResult
      return DiagnosisResult(
        disease: diseaseName,
        severity: severity,
        recommendations: recommendations,
        plantName: plantName,
        confidence: confidence,
        description: widget.scanData['description']?.toString(),
        scientificName: widget.scanData['scientificName']?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error creating DiagnosisResult: $e');

      // Return a healthy default
      return const DiagnosisResult(
        disease: 'Healthy',
        severity: 'None',
        recommendations: [
          'Please consult an agricultural expert for proper diagnosis'
        ],
        plantName: 'Plant',
        confidence: '0',
      );
    }
  }
}