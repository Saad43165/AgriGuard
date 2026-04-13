import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/ai_analysis_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../core/services/disease_id_service.dart';
import '../../../core/services/plant_id_service.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'components/capture_app_bar.dart';
import 'components/capture_info_dialog.dart';
import 'components/method_selection_screen.dart';
import 'components/processing_overlay.dart';
import 'components/source_selection_screen.dart';
import 'components/welcome_screen.dart';

class CaptureScreen extends StatefulWidget {
  final bool startOnDevice;
  final bool startAdvanced;

  const CaptureScreen({
    super.key,
    this.startOnDevice = false,
    this.startAdvanced = false,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  // Step management
  int _currentStep = 0;
  String? _selectedMethod;

  XFile? _imageFile;
  bool _isLoading = false;
  bool _isProcessing = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  // Services
  final PlantIdService _plantService = PlantIdService();
  final DiseaseIdService _diseaseService = DiseaseIdService();
  late final PlantAnalysisService _analysisService;
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _analysisService = PlantAnalysisService(
      speciesService: _plantService,
      diseaseService: _diseaseService,
    );
    _initializeServices();

    // Apply startup mode passed in via constructor props.
    // This is the ONLY place startup flags are consumed — we never read
    // them from route arguments because CaptureScreen lives inside a PageView
    // and ModalRoute.of(context) would return the parent route, which may
    // carry stale arguments from a previous Home quick-scan navigation.
    if (widget.startOnDevice) {
      _selectedMethod = 'tflite';
      _currentStep = 2;
    } else if (widget.startAdvanced) {
      _selectedMethod = 'api';
      _currentStep = 2;
    }
  }

  // didChangeDependencies intentionally does NOT read route arguments.
  // Reason: CaptureScreen is embedded in a PageView inside MainNavigationScreen.
  // ModalRoute.of(context) resolves to the *parent* named route, which retains
  // its arguments across the lifetime of MainNavigationScreen. If HomeScreen
  // previously pushed AppRoutes.scan with startOnDevice/startAdvanced, those
  // arguments stay on the stack and would incorrectly skip the Welcome screen
  // every time the user taps the navbar scan tab.
  //
  // Startup flags are injected exclusively via widget constructor props
  // (see openScanTab in MainNavigationScreen / mainNavKey).

  Future<void> _initializeServices() async {
    await _guestService.initialize();
    await _initializeModels();
    if (mounted) setState(() {});
  }

  Future<void> _initializeModels() async {
    try {
      debugPrint('🔄 Loading both AI models...');
      await Future.wait([
        _plantService.loadModel(),
        _diseaseService.loadModel(),
      ]);
      debugPrint('✅ Both models loaded successfully');
      debugPrint('   Plant ID Model: ${_plantService.isLoaded ? "✅" : "❌"}');
      debugPrint('   Disease Model: ${_diseaseService.isLoaded ? "✅" : "❌"}');
    } catch (e) {
      debugPrint('❌ Model initialization error: $e');
      if (mounted) {
        _showErrorSnackBar('error_load_models');
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _plantService.dispose();
    _diseaseService.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    setState(() => _currentStep = 1);
  }

  void _selectMethod(String method) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedMethod = method;
      _currentStep = 2;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      _showGuestLimitDialog();
      return;
    }

    try {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted) return;

      if (picked != null) {
        setState(() => _imageFile = picked);
        if (_selectedMethod == 'tflite') {
          _processWithTFLite();
        } else {
          _navigateToAdvancedSearch();
        }
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar('error_pick_image');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToAdvancedSearch() {
    if (_imageFile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchScreen(
          originalScanData: {
            'imagePath': _imageFile!.path,
            'timestamp': DateTime.now().toIso8601String(),
            'method': 'api',
          },
        ),
      ),
    ).then((_) => _resetState());
  }

  Future<void> _processWithTFLite() async {
    if (!mounted || _imageFile == null || _isProcessing) return;
    final t = Provider.of<TranslationService>(context, listen: false);

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _currentStep = 3;
    });

    try {
      User? user;
      if (!_guestService.isGuestMode) {
        user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception(t.get('error_sign_in'));
      }

      final imageFile = File(_imageFile!.path);
      if (!await imageFile.exists()) {
        throw Exception(t.get('error_file_not_found'));
      }

      debugPrint('🤖 Starting unified on-device analysis...');
      final analysisResult = await _analysisService.analyzePlant(imageFile);

      if (!mounted) return;

      if (_guestService.isGuestMode) {
        final success = await _guestService.incrementScanCount();
        if (!success) {
          _showGuestLimitDialog();
          setState(() => _isProcessing = false);
          return;
        }
      }

      final scanData = _prepareScanDataFromAnalysis(analysisResult, user);
      if (!mounted) return;

      await Navigator.pushNamed(context, AppRoutes.results,
          arguments: {'scanData': scanData});

      _resetState();
    } catch (e) {
      debugPrint('❌ Process error: $e');
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() => _isProcessing = false);
      _showErrorSnackBar('error_pick_image');
    }
  }

  Map<String, dynamic> _prepareScanDataFromAnalysis(
      Map<String, dynamic> analysis,
      User? user,
      ) {
    final plantName = analysis['plantName']?.toString() ??
        analysis['species']?.toString() ??
        'Unknown Plant';

    final diseaseName = analysis['diseaseName']?.toString() ??
        analysis['disease']?.toString() ??
        'Healthy';

    final isHealthy = analysis['isHealthy'] as bool? ??
        diseaseName.toLowerCase() == 'healthy';

    final isLeaf = analysis['isLeaf'] as bool? ?? true;
    final guestMode = _guestService.isGuestMode;
    final shouldSaveToHistory =
    guestMode ? false : (analysis['shouldSaveToHistory'] as bool? ?? true);

    final rawConfidence =
        analysis['confidence'] ?? analysis['diseaseConfidence'] ?? 0.0;
    final confidence = (rawConfidence is num)
        ? rawConfidence.toStringAsFixed(1)
        : rawConfidence.toString();

    final speciesConf = analysis['speciesConfidence'];
    final plantConfidence = (speciesConf is num)
        ? (speciesConf * 100).toStringAsFixed(1)
        : (analysis['plantConfidence']?.toString() ?? '0');

    final remediation = analysis['remediation'];
    final remediationList =
    remediation is List ? List<String>.from(remediation) : <String>[];

    String diagnosis;
    if (!isLeaf) {
      diagnosis = '❌ Non-leaf image detected';
    } else if (analysis['isUnknown'] == true) {
      diagnosis = 'Unable to identify plant with confidence';
    } else if (isHealthy) {
      diagnosis = '✅ Healthy $plantName plant identified';
    } else {
      diagnosis = '⚠️ $diseaseName detected on $plantName';
    }

    String treatment;
    if (!isLeaf) {
      treatment = '• Please upload a clear photo of a plant leaf';
    } else if (remediationList.isNotEmpty) {
      treatment = '• ${remediationList.join('\n• ')}';
    } else if (isHealthy) {
      treatment =
      '• Continue regular care routine\n• Monitor for any signs of disease or pests\n• Apply balanced fertilizer as needed';
    } else {
      treatment =
      '• Consult agricultural expert for specific treatment\n• Isolate affected plant to prevent spread\n• Apply appropriate fungicide based on diagnosis';
    }

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'identified',
      'cropType': plantName,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'diagnosis': diagnosis,
      'confidence': confidence,
      'plantConfidence': plantConfidence,
      'treatment': treatment,
      'severity': analysis['severity']?.toString() ??
          (isHealthy ? 'None' : 'Unknown'),
      'cause': analysis['cause']?.toString() ??
          analysis['primaryMessage']?.toString() ??
          'Requires analysis',
      'symptoms': analysis['symptoms'] ?? const <String>[],
      'symptomsText':
      (analysis['symptoms'] is List &&
          (analysis['symptoms'] as List).isNotEmpty)
          ? (analysis['symptoms'] as List).join('\n• ')
          : 'No specific symptoms identified',
      'precautions': analysis['precautions'] ?? const <String>[],
      'precautionsText':
      (analysis['precautions'] is List &&
          (analysis['precautions'] as List).isNotEmpty)
          ? (analysis['precautions'] as List).join('\n• ')
          : '• Maintain proper plant care\n• Regular monitoring\n• Adequate watering',
      'remediation': remediationList,
      'imagePath': _imageFile!.path,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': user?.uid ?? 'guest',
      'fromCapture': true,
      'previousRoute': AppRoutes.scan,
      'isUnknown': analysis['isUnknown'] as bool? ?? false,
      'isHealthy': isHealthy,
      'isLeaf': isLeaf,
      'leafConfidence': analysis['leafConfidence'],
      'leafAnalysis': analysis['_leafAnalysis'] ?? analysis['leafAnalysis'],
      'shouldSaveToHistory': shouldSaveToHistory,
      'skipSave': shouldSaveToHistory ? false : true,
      'rawLabel': analysis['rawLabel'],
      'analysisMethod': 'tflite_orchestrated',
      'hasDiseaseAnalysis': analysis['hasDiseaseData'] as bool? ?? true,
      'isGuestScan': _guestService.isGuestMode,
      'rawAnalysis': analysis,
    };
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _imageFile = null;
        _isProcessing = false;
        _currentStep = 0;
        _selectedMethod = null;
      });
    }
  }

  void _showGuestLimitDialog() {
    final t = Provider.of<TranslationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        icon: Icon(
          Icons.block_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: t.get('limit_reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.get('limit_message')),
            const SizedBox(height: 12),
            Text(t.get('limit_benefit')),
          ],
        ),
        actions: [
          AppDialogActions.secondary(
            context,
            label: t.get('cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogActions.primary(
            context,
            label: t.get('sign_in_now'),
            icon: Icons.login_rounded,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
                  (route) => false,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String messageKey) {
    if (!mounted) return;
    final t = Provider.of<TranslationService>(context, listen: false);
    final message = t.get(messageKey);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.length > 100
                    ? '${message.substring(0, 100)}...'
                    : message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: t.get('dismiss'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedMethod = null;
          _imageFile = null;
        }
      });
    }
  }

  String _getAppBarTitle() {
    final t = Provider.of<TranslationService>(context, listen: false);
    switch (_currentStep) {
      case 0:
        return t.get('app_title');
      case 1:
        return t.get('analysis_method');
      case 2:
        return t.get('image_source');
      case 3:
        return t.get('analyzing');
      default:
        return t.get('app_title');
    }
  }

  String _getProcessingMessage() {
    final t = Provider.of<TranslationService>(context, listen: false);
    if (_selectedMethod == 'tflite') {
      return '${t.get('processing_ai')}\n${t.get('processing_plant')}\n${t.get('processing_disease')}';
    }
    return t.get('processing_text');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isProcessing && _currentStep == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentStep > 0) _goBack();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CaptureAppBar(
          currentStep: _currentStep,
          isProcessing: _isProcessing,
          appBarTitle: _getAppBarTitle(),
          onBackPressed: _isProcessing ? null : _goBack,
          onInfoPressed: _currentStep == 0
              ? () => showDialog(
            context: context,
            builder: (context) => const CaptureInfoDialog(),
          )
              : null,
        ),
        body: Container(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF),
          child: Stack(
            children: [
              ...List.generate(
                8,
                    (i) => FloatingOrb(
                  index: i,
                  maxWidth: MediaQuery.of(context).size.width,
                  fadeController: _fadeController,
                  scaleAnimation: _scaleAnimation,
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStep(),
                ),
              ),
              if (_isProcessing)
                ProcessingOverlay(
                  selectedMethod: _selectedMethod ?? '',
                  isProcessing: _isProcessing,
                  isGuestMode: _guestService.isGuestMode,
                  remainingScans: _guestService.remainingScans,
                  pulseAnimation: _pulseAnimation,
                  processingMessage: _getProcessingMessage(),
                  modelStatuses: {
                    'Plant ID': _plantService.isLoaded,
                    'Disease Detection': _diseaseService.isLoaded,
                  },
                  onCancel: () {
                    if (_isProcessing && mounted) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isProcessing = false;
                        _currentStep = 2; // Return to source selection, not method selection
                      });
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Single unified screen — method + source selection in one place
        return WelcomeScreen(
          scaleAnimation: _scaleAnimation,
          isGuestMode: _guestService.isGuestMode,
          remainingScans: _guestService.remainingScans,
          modelStatuses: {
            'Plant ID Model': _plantService.isLoaded,
            'Disease Model': _diseaseService.isLoaded,
          },
          onStartScan: _startScanning,
          isTFLiteReady: _plantService.isLoaded && _diseaseService.isLoaded,
          isAdvancedAllowed: !_guestService.isGuestMode,
          advancedUnavailableReason: _guestService.isGuestMode
              ? _guestService.getRestrictionMessage('access_advanced')
              : null,
          onLaunch: (method, source) {
            _selectedMethod = method;
            _pickImage(source);
          },
        );
      default:
        return Container();
    }
  }
}