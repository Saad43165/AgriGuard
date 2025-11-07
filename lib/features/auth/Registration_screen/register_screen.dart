import 'dart:io';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/login_prompt.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_button.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_form.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../auth_services.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
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

  XFile? _imageFile;
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
      setState(() => _isLoading = true);

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
        _showSnackBar(
          message: 'Profile image selected successfully',
          isError: false,
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar(message: 'Failed to select image: $e', isError: true);
      debugPrint('Image picker error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FIXED: Now takes a real UID (passed after user creation)
  Future<String?> _uploadProfileImage(String uid) async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
      final uploadTask = storageRef.putFile(File(_imageFile!.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'storage/object-not-found') {
        _showSnackBar(
          message: 'Upload path invalid. Please try again.',
          isError: true,
        );
      } else {
        _showSnackBar(
          message: 'Failed to upload profile image: ${e.message}',
          isError: true,
        );
      }
      debugPrint('Storage error (${e.code}): ${e.message}');
      return null;
    } catch (e) {
      _showSnackBar(
        message: 'Failed to upload profile image: $e',
        isError: true,
      );
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // FIXED: Reordered logic - create user first, then upload, then save details
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ----- 1. Gather form data -----
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      final farmSize = _farmSizeController.text.trim();

      // ----- 2. Create Firebase Auth user (gets UID) -----
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      final uid = user.uid;

      // ----- 3. Send verification email (optional but recommended) -----
      await user.sendEmailVerification();

      // ----- 4. Upload profile image (now we have a valid uid) -----
      String? profileImageUrl;
      if (_imageFile != null) {
        profileImageUrl = await _uploadProfileImage(uid);
      }

      // ----- 5. Save everything to Firestore -----
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'location': location,
        'farmSize': farmSize,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ----- 6. Success UI -----
      if (mounted) {
        _showDetailedSnackBar(
          title: 'Registration Successful',
          message:
          'Please check your email for a verification link. You must verify your email to log in.',
          errorCode: 'email-verification-sent',
        );
        await Future.delayed(const Duration(milliseconds: 2000));
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // … your existing error handling …
    } on FirebaseException catch (e) {
      // Storage-specific errors
      _showSnackBar(
          message: 'Upload failed: ${e.message ?? e.code}', isError: true);
    } catch (e) {
      _showErrorSnackBar('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _showSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color:
              isError
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
            SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                  isError
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
        action:
        isError && message.contains('already registered')
            ? SnackBarAction(
          label: 'Login',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.login);
          },
        )
            : null,
      ),
    );
  }

  void _showDetailedSnackBar({
    required String title,
    required String message,
    required String errorCode,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  errorCode == 'email-verification-sent'
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color:
                  errorCode == 'email-verification-sent'
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onError,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                ),
                SizedBox(
                  width: AppMeasurements.getResponsiveSmallPadding(context),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                    errorCode == 'email-verification-sent'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: AppMeasurements.getResponsiveSmallPadding(context),
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                errorCode == 'email-verification-sent'
                    ? Theme.of(
                  context,
                ).colorScheme.onPrimary.withOpacity(0.9)
                    : Theme.of(
                  context,
                ).colorScheme.onError.withOpacity(0.9),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        errorCode == 'email-verification-sent'
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: const Duration(seconds: 6),
        action:
        errorCode == 'email-verification-sent'
            ? SnackBarAction(
          label: 'Resend Email',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            try {
              await FirebaseAuth.instance.currentUser
                  ?.sendEmailVerification();
              _showSnackBar(
                message:
                'Verification email resent. Check your inbox or spam folder.',
                isError: false,
              );
            } catch (e) {
              _showErrorSnackBar('Failed to resend email: $e');
            }
          },
        )
            : errorCode == 'email-already-in-use'
            ? SnackBarAction(
          label: 'Login',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.login);
          },
        )
            : null,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message: message, isError: true);
  }

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
                    onPasswordVisibilityChanged: () => setState(() => _obscurePassword = !_obscurePassword),
                    onConfirmPasswordVisibilityChanged: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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