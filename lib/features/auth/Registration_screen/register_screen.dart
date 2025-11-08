import 'dart:io';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/login_prompt.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_button.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_form.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_header.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/utils/snackbar_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin, ScreenAnimationMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    disposeAnimations();
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
        final file = File(pickedFile.path);
        setState(() => _imageFile = file);
        SnackbarUtils.showImageSuccessSnackBar(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      SnackbarUtils.showImageErrorSnackBar(context, e.toString());
      debugPrint('Image picker error: $e');
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      SnackbarUtils.showUploadErrorSnackBar(context, e.message ?? e.code);
      debugPrint('Storage error (${e.code}): ${e.message}');
      return null;
    } catch (e) {
      SnackbarUtils.showUploadErrorSnackBar(context, e.toString());
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if image is still accessible
    if (_imageFile != null && !await _imageFile!.exists()) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Selected image is no longer accessible. Please select again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Gather form data
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      final farmSize = _farmSizeController.text.trim();

      // 2. Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      final uid = user.uid;

      // 3. Upload profile image
      String? profileImageUrl;
      if (_imageFile != null && await _imageFile!.exists()) {
        profileImageUrl = await _uploadProfileImage(uid);
      }

      // 4. Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'location': location,
        'farmSize': farmSize,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // 5. Send verification email
      await user.sendEmailVerification();

      // 6. Success handling
      if (mounted) {
        SnackbarUtils.showRegistrationSuccessSnackBar(context);

        // Navigate to login after delay
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
                (route) => false
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } on FirebaseException catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Firebase error: ${e.message ?? e.code}',
      );
    } catch (e) {
      SnackbarUtils.showUnexpectedErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        SnackbarUtils.showEmailAlreadyInUseSnackBar(context);
        break;
      case 'weak-password':
        SnackbarUtils.showWeakPasswordSnackBar(context);
        break;
      case 'invalid-email':
        SnackbarUtils.showInvalidEmailSnackBar(context);
        break;
      case 'operation-not-allowed':
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Email/password accounts are not enabled. Please contact support.',
        );
        break;
      case 'network-request-failed':
        SnackbarUtils.showNetworkErrorSnackBar(context);
        break;
      default:
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Registration failed: ${e.message}',
        );
    }
  }

  // ... rest of your build method remains exactly the same ...
  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'Create Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 24,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: smallPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context),
              ),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.all(smallPadding),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.of(context).isDarkMode
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF16213E),
              Color(0xFF1A1A2E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.9),
              Theme.of(context).colorScheme.background.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: applyAnimations(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegisterHeader(
                    imageFile: _imageFile,
                    onImagePressed: _pickImage,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: padding),
                  RegisterForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    phoneController: _phoneController,
                    locationController: _locationController,
                    farmSizeController: _farmSizeController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onPasswordVisibilityChanged: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onConfirmPasswordVisibilityChanged: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  SizedBox(height: smallPadding),
                  RegisterButton(
                    onPressed: _isLoading ? () {} : _register,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: smallPadding),
                  const LoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}