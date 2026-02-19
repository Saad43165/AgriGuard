import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:agriguard_fyp/features/auth/Registration_screen/utils/snackbar_utils.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_app_bar.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/step/step_one.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/step/step_two.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../Forget_Pass_Screen/constants/app_colors.dart';
import '../../Profile/utils/profile_image_manager.dart';
import 'widgets/step/step_three.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Keys
  final GlobalKey<FormState> _stepOneKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _stepTwoKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _stepThreeKey = GlobalKey<FormState>();

  // ADDED: Keys to access step states
  final GlobalKey<StepOneState> _stepOneStateKey = GlobalKey<StepOneState>();
  final GlobalKey<StepTwoState> _stepTwoStateKey = GlobalKey<StepTwoState>();
  final GlobalKey<StepThreeState> _stepThreeStateKey = GlobalKey<StepThreeState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      HapticFeedback.lightImpact();
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        SnackbarUtils.showImageSuccessSnackBar(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      SnackbarUtils.showImageErrorSnackBar(context, e.toString());
    }
  }

  void _nextStep() {
    bool isValid = false;

    // FIXED: Enable autovalidation BEFORE validating
    switch (_currentStep) {
      case 0:
      // Enable autovalidation in Step One
        _stepOneStateKey.currentState?.enableAutoValidation();
        isValid = _stepOneKey.currentState?.validate() ?? false;
        break;
      case 1:
      // Step 2 is optional, always valid
        _stepTwoStateKey.currentState?.enableAutoValidation();
        isValid = _stepTwoKey.currentState?.validate() ?? true;
        break;
      case 2:
      // Enable autovalidation in Step Three
        _stepThreeStateKey.currentState?.enableAutoValidation();
        isValid = _stepThreeKey.currentState?.validate() ?? false;
        break;
    }

    if (isValid) {
      if (_currentStep < 2) {
        HapticFeedback.lightImpact();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _register();
      }
    } else {
      // ADDED: Better error feedback
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentStep == 0
                      ? 'Please fill in your name and email'
                      : _currentStep == 2
                      ? 'Please enter and confirm your password'
                      : 'Please check your inputs',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_imageFile == null) return null;

    try {
      if (!await _imageFile!.exists()) return null;
      final bytes = await _imageFile!.readAsBytes();
      Uint8List compressedBytes = bytes;

      if (bytes.length > 500000) {
        final codec = await instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
        compressedBytes = byteData!.buffer.asUint8List();
      }

      return base64Encode(compressedBytes);
    } catch (e) {
      debugPrint('❌ Base64 conversion error: $e');
      return null;
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      final farmSize = _farmSizeController.text.trim();

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user == null) throw Exception('User creation failed');

      final uid = user.uid;

      String? profileImageUrl;
      if (_imageFile != null && await _imageFile!.existsSync()) {
        profileImageUrl = await _uploadProfileImage(uid);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'location': location,
        'farmSize': farmSize,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'uid': uid,
      });

      await user.sendEmailVerification();

      if (mounted) {
        if (_imageFile != null) {
          ProfileImageManager.setPendingImage(_imageFile!);
        }

        HapticFeedback.mediumImpact();
        await _showSuccessDialog();

        await FirebaseAuth.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      _handleFirebaseAuthError(e);
    } catch (e) {
      HapticFeedback.heavyImpact();
      SnackbarUtils.showUnexpectedErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
            ),
            const SizedBox(height: 28),
            Text(
              'Account Created!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'A verification email has been sent to:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _emailController.text.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Please check your inbox and verify your email to login',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        SnackbarUtils.showEmailAlreadyInUseSnackBar(context);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'weak-password':
        SnackbarUtils.showWeakPasswordSnackBar(context);
        break;
      case 'invalid-email':
        SnackbarUtils.showInvalidEmailSnackBar(context);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      default:
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Registration failed: ${e.message}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.of(context).isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: RegisterAppBar(
          currentStep: _currentStep,
          onBackPressed: _currentStep > 0 ? _previousStep : _goToLogin,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
              stops: AppColors.gradientStops,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentStep = index),
                    children: [
                      StepOne(
                        key: _stepOneStateKey, // ADDED: State key
                        formKey: _stepOneKey,
                        nameController: _nameController,
                        emailController: _emailController,
                        imageFile: _imageFile,
                        onImagePick: _pickImage,
                      ),
                      StepTwo(
                        key: _stepTwoStateKey, // ADDED: State key
                        formKey: _stepTwoKey,
                        phoneController: _phoneController,
                        locationController: _locationController,
                        farmSizeController: _farmSizeController,
                      ),
                      StepThree(
                        key: _stepThreeStateKey, // ADDED: State key
                        formKey: _stepThreeKey,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                      ),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: isActive
                          ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                          : null,
                      color: isActive
                          ? null
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final padding = AppMeasurements.getResponsivePadding(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Back',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: _isLoading ? null : _nextStep,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [
                      Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                    ]
                        : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? 'Create Account' : 'Next',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}