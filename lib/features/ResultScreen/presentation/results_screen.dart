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
import '../../home/screens/components/scan_service.dart';
import 'components/analysis_details_Card.dart';
import 'components/diagnosis_card.dart';
import 'components/diagnosis_result.dart';
import 'components/disease_cause_card.dart';
import 'components/floating_advance_search_banner.dart';
import 'components/recommentations_card.dart';
import 'components/scanned_image_Section.dart';

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
  bool _isAutoSaved = false;
  bool _showAdvancedSearchBanner = false;

  // JSON data
  Map<String, dynamic> _diseaseCauses = {};
  Map<String, dynamic> _diseaseMapping = {};
  bool _jsonLoaded = false;
  List<String> _diseaseCausesList = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadJsonData();
    _autoSaveScan();
    _scheduleAdvancedSearchBanner();
  }

  Future<void> _loadJsonData() async {
    try {
      debugPrint('📚 Loading JSON data...');

      // Load disease causes JSON
      final causesJson = await rootBundle.loadString('assets/data/disease_causes.json');
      _diseaseCauses = json.decode(causesJson);
      debugPrint('✅ Disease causes loaded: ${_diseaseCauses.keys.length} entries');

      // Load disease mapping JSON
      final mappingJson = await rootBundle.loadString('assets/data/disease_mapping.json');
      _diseaseMapping = json.decode(mappingJson);
      debugPrint('✅ Disease mapping loaded: ${_diseaseMapping.keys.length} entries');

      // Extract causes for current disease
      _extractDiseaseCauses();

      setState(() {
        _jsonLoaded = true;
      });

    } catch (e) {
      debugPrint('❌ Error loading JSON data: $e');
      // Provide fallback empty data
      _diseaseCauses = {};
      _diseaseMapping = {};
      _diseaseCausesList = [];
      _jsonLoaded = true;
    }
  }

  void _extractDiseaseCauses() {
    try {
      final rawLabel = widget.scanData['rawLabel']?.toString();
      final diseaseName = widget.scanData['diseaseName']?.toString();
      final plantName = widget.scanData['plantName']?.toString();

      debugPrint('🔍 Extracting disease causes for:');
      debugPrint('   Raw Label: $rawLabel');
      debugPrint('   Disease Name: $diseaseName');
      debugPrint('   Plant Name: $plantName');

      // CHECK 1: If analysis completely failed
      if (diseaseName == null ||
          diseaseName.toLowerCase().contains('unable to determine') ||
          diseaseName.toLowerCase().contains('image quality issue') ||
          diseaseName.toLowerCase().contains('analysis required')) {
        debugPrint('⚠️ Analysis failed - showing appropriate message');
        _diseaseCausesList = [
          'Analysis could not be completed successfully',
          'This may be due to poor image quality or unclear symptoms',
          'Please try again with a clearer photo'
        ];
        return;
      }

      // CHECK 2: If plant is "Unknown Plant" or "Unable to Determine"
      if (plantName == null ||
          plantName.toLowerCase().contains('unknown') ||
          plantName.toLowerCase().contains('unable to determine')) {
        debugPrint('⚠️ Plant not identified - showing generic causes');
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

      // CHECK 3: If plant is healthy
      final isHealthy = diseaseName.toLowerCase() == 'healthy' ||
          diseaseName.toLowerCase().contains('healthy') ||
          (widget.scanData['isHealthy'] as bool? ?? false);

      if (isHealthy) {
        debugPrint('✅ Plant is healthy - showing healthy causes');
        _diseaseCausesList = [
          'Plant appears to be in good health',
          'No visible signs of disease or stress',
          'Maintaining current care practices is recommended'
        ];
        return;
      }

      // CHECK 4: If confidence is very low
      final confidence = double.tryParse(widget.scanData['confidence']?.toString() ?? '0') ?? 0;
      if (confidence < 30.0) {
        debugPrint('⚠️ Low confidence diagnosis - showing cautious causes');
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

      // Only proceed with specific disease causes if all checks pass
      // Try different methods to find the disease in JSON
      String? diseaseKey;

      // Method 1: Direct match with raw label (e.g., "Bell_pepper___healthy")
      if (rawLabel != null && _diseaseCauses.containsKey(rawLabel)) {
        diseaseKey = rawLabel;
        debugPrint('✅ Found disease by raw label: $diseaseKey');
      }
      // Method 2: Check in disease mapping first
      else if (rawLabel != null && _diseaseMapping.containsKey(rawLabel)) {
        final displayName = _diseaseMapping[rawLabel]['display_name']?.toString();
        if (displayName != null) {
          // Try to find in disease causes with format "Plant - Disease"
          final searchKey = _findDiseaseKeyByDisplayName(displayName);
          if (searchKey != null) {
            diseaseKey = searchKey;
            debugPrint('✅ Found disease by display name: $diseaseKey');
          }
        }
      }
      // Method 3: Construct key from plant and disease
      else if (plantName != null && diseaseName != null) {
        final constructedKey = '${plantName.replaceAll(' ', '_')}___${diseaseName.replaceAll(' ', '_').toLowerCase()}';
        if (_diseaseCauses.containsKey(constructedKey)) {
          diseaseKey = constructedKey;
          debugPrint('✅ Found disease by constructed key: $diseaseKey');
        }
      }

      // Get causes from the found key
      if (diseaseKey != null && _diseaseCauses.containsKey(diseaseKey)) {
        final diseaseData = _diseaseCauses[diseaseKey];
        if (diseaseData is Map && diseaseData.containsKey('causes')) {
          final causes = diseaseData['causes'];
          if (causes is List && causes.isNotEmpty) {
            _diseaseCausesList = List<String>.from(causes);
            debugPrint('✅ Extracted ${_diseaseCausesList.length} specific causes');
          }
        }
      }

      // If no specific causes found, try general causes based on disease type
      if (_diseaseCausesList.isEmpty) {
        _tryGeneralCauses(diseaseName!);
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
      // Convert "Plant - Disease" format to "Plant___Disease" format
      if (displayName.contains(' - ')) {
        final parts = displayName.split(' - ');
        if (parts.length == 2) {
          final plant = parts[0].replaceAll(' ', '_');
          final disease = parts[1].replaceAll(' ', '_').toLowerCase();
          final key = '${plant}___$disease';

          // Try exact match
          if (_diseaseCauses.containsKey(key)) {
            return key;
          }

          // Try with healthy
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

      // Check general disease categories
      if (_diseaseCauses.containsKey('general_disease_causes')) {
        final generalCauses = _diseaseCauses['general_disease_causes'];
        if (generalCauses is Map) {
          // Try to match disease type
          if (lowerDisease.contains('spot') && generalCauses.containsKey('bacterial_spot')) {
            final causes = generalCauses['bacterial_spot']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
              debugPrint('✅ Using general bacterial spot causes');
            }
          } else if (lowerDisease.contains('blight') && generalCauses.containsKey('blight')) {
            final causes = generalCauses['blight']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
              debugPrint('✅ Using general blight causes');
            }
          } else if (lowerDisease.contains('rust') && generalCauses.containsKey('rust_disease')) {
            final causes = generalCauses['rust_disease']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
              debugPrint('✅ Using general rust causes');
            }
          } else if (lowerDisease.contains('mildew') && generalCauses.containsKey('powdery_mildew')) {
            final causes = generalCauses['powdery_mildew']['general_causes'];
            if (causes is List) {
              _diseaseCausesList = List<String>.from(causes);
              debugPrint('✅ Using general powdery mildew causes');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error trying general causes: $e');
    }
  }

  void _useFallbackCauses(String? plantName, String? diseaseName) {
    debugPrint('⚠️ Using fallback causes');

    // Check if plant is healthy
    if (diseaseName?.toLowerCase() == 'healthy' || diseaseName == null) {
      _diseaseCausesList = [
        'Plant appears to be in good health',
        'No visible signs of disease or stress',
        'Maintaining current care practices is recommended'
      ];
    } else {
      // General disease causes
      _diseaseCausesList = [
        'Pathogen infection (fungal, bacterial, or viral)',
        'Environmental stress factors',
        'Unfavorable weather conditions',
        'Poor plant management practices',
        'Susceptible plant variety'
      ];
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

  Future<void> _autoSaveScan() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      // Get diagnosis result
      final diagnosisResult = _getDiagnosisResult();

      dynamic timestampToSave = widget.scanData['timestamp'];
      if (timestampToSave is Timestamp) {
        timestampToSave = timestampToSave.toDate().toIso8601String();
      }

      await ScanService().saveScan({
        'id': widget.scanData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrl': widget.scanData['imageUrl'],
        'imagePath': widget.scanData['imagePath'],
        'diagnosis': diagnosisResult.disease,
        'confidence': diagnosisResult.confidence,
        'treatment': diagnosisResult.recommendations.join('. '),
        'timestamp': timestampToSave ?? DateTime.now().toIso8601String(),
        'severity': diagnosisResult.severity,
        'plantName': diagnosisResult.plantName,
        'cropType': widget.scanData['cropType'] ?? 'Unknown',
        'cause': widget.scanData['cause'] ?? 'Pathogen infection or environmental stress',
        'symptoms': (widget.scanData['symptoms'] as List<String>?)?.join(', ') ?? '',
        'isHealthy': diagnosisResult.isHealthy,
      });

      if (mounted) {
        setState(() {
          _isAutoSaved = true;
        });
      }
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
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

    String? actualImagePath = imageUrl ?? imagePath;
    bool hasLocalImage = false;

    if (actualImagePath != null && actualImagePath.isNotEmpty) {
      try {
        final file = File(actualImagePath);
        hasLocalImage = file.existsSync();
      } catch (e) {
        debugPrint('Error checking file existence: $e');
        hasLocalImage = false;
      }
    }

    final bool hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');
    final bool hasImage = hasLocalImage || hasNetworkImage;

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
                      // 1. Scanned Image at the top
                      if (hasImage)
                        Column(
                          children: [
                            if (hasLocalImage && actualImagePath != null)
                              ScannedImageSection(imagePath: actualImagePath)
                            else if (hasNetworkImage)
                              _buildNetworkImage(imageUrl!, theme)
                            else
                              _buildNoImagePlaceholder(theme),
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

                      // 2. Diagnosis Card (Plant Name + Disease + Severity)
                      DiagnosisCard(diagnosisResult: diagnosisResult),
                      const SizedBox(height: 20),

                      // 3. Analysis Details Card
                      AnalysisDetailsCard(scanData: widget.scanData),
                      const SizedBox(height: 20),

                      // 4. Disease Causes Card (NEW)
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

              if (_isSaving)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Saving report...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

  Widget _buildNetworkImage(String imageUrl, ThemeData theme) {
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
        child: Image.network(
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
        ),
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

  DiagnosisResult _getDiagnosisResult() {
    try {
      debugPrint('🔍 DEBUG - Starting diagnosis result parsing');
      debugPrint('🔍 Available keys: ${widget.scanData.keys.toList()}');

      // Get plant name - check multiple sources
      String plantName = widget.scanData['plantName']?.toString() ?? 'Unknown Plant';

      // Get disease information
      String diseaseName = widget.scanData['diseaseName']?.toString() ??
          widget.scanData['diagnosis']?.toString() ??
          'Healthy';

      // Check if disease name contains plant information (e.g., "Grape___Leaf_blight")
      String diseasePlantName = '';
      if (widget.scanData['rawLabel'] != null &&
          widget.scanData['rawLabel'].toString().contains('___')) {
        final parts = widget.scanData['rawLabel'].toString().split('___');
        if (parts.length >= 2) {
          diseasePlantName = parts[0].replaceAll('_', ' ').trim();
        }
      }

      // RESOLVE CONFLICT: If disease model says different plant than plant ID model
      if (diseasePlantName.isNotEmpty &&
          diseasePlantName.toLowerCase() != plantName.toLowerCase() &&
          diseasePlantName != 'Unknown Plant') {

        debugPrint('⚠️ Plant conflict detected!');
        debugPrint('   Plant ID model says: $plantName');
        debugPrint('   Disease model says: $diseasePlantName');

        // Prefer the plant from disease model when disease is detected
        if (diseaseName.toLowerCase() != 'healthy') {
          debugPrint('✅ Using plant from disease model: $diseasePlantName');
          plantName = diseasePlantName;
        }
      }

      String confidence = widget.scanData['confidence']?.toString() ?? '0';
      String severity = widget.scanData['severity']?.toString() ?? 'Medium';

      // Determine if plant is actually healthy
      bool isHealthy = diseaseName.toLowerCase() == 'healthy' ||
          diseaseName.toLowerCase().contains('no disease');

      // Adjust severity for healthy plants
      if (isHealthy) {
        severity = 'None';
      }

      debugPrint('📊 Final parsed data:');
      debugPrint('  Plant: $plantName');
      debugPrint('  Disease: $diseaseName');
      debugPrint('  Confidence: $confidence%');
      debugPrint('  Severity: $severity');
      debugPrint('  Is Healthy: $isHealthy');

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
      debugPrint('Stack trace: ${e.toString()}');

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