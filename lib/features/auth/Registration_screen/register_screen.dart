// features/auth/Registration_screen/register_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:agriguard_fyp/features/auth/Registration_screen/utils/snackbar_utils.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/login_prompt.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/profile_image.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_button.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_form.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_app_bar.dart';
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
import '../../Profile/utils/profile_image_manager.dart'; // ← CORRECT IMPORT

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
    if (_imageFile == null) {
      debugPrint('❌ No image file to convert');
      return null;
    }

    try {
      debugPrint('🖼️ === CONVERTING IMAGE TO BASE64 ===');
      debugPrint('📁 Image path: ${_imageFile!.path}');

      // Check if file exists
      if (!await _imageFile!.exists()) {
        debugPrint('❌ Image file does not exist');
        return null;
      }

      // Read image as bytes
      final bytes = await _imageFile!.readAsBytes();
      debugPrint('📊 Original file size: ${bytes.length} bytes');

      // Compress image if too large (optional)
      Uint8List compressedBytes = bytes;
      if (bytes.length > 500000) { // 500KB
        debugPrint('⚡ Compressing large image...');
        compressedBytes = await _compressImage(bytes);
        debugPrint('📊 Compressed size: ${compressedBytes.length} bytes');
      }

      // Convert to base64 string
      final base64Image = base64Encode(compressedBytes);
      debugPrint('✅ Image converted to Base64');
      debugPrint('📊 Base64 string length: ${base64Image.length} characters');

      return base64Image;

    } catch (e) {
      debugPrint('❌ Base64 conversion error: $e');
      return null;
    }
  }

// Optional: Image compression function
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile != null && !await _imageFile!.exists()) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Selected image is no longer accessible. Please select again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      final farmSize = _farmSizeController.text.trim();

      debugPrint('Starting registration for: $email');

      // Create user in Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user == null) throw Exception('User creation failed');

      final uid = user.uid;
      debugPrint('User created with UID: $uid');

      // Upload profile image if exists
      String? profileImageUrl;
      if (_imageFile != null && await _imageFile!.exists()) {
        debugPrint('🖼️ Converting profile image to Base64...');
        profileImageUrl = await _uploadProfileImage(uid);

        if (profileImageUrl != null) {
          debugPrint('✅ Profile image converted to Base64 successfully!');
          debugPrint('📊 Base64 data length: ${profileImageUrl.length}');
        } else {
          debugPrint('❌ Image conversion failed - setting to null');
          profileImageUrl = null;
        }
      } else {
        debugPrint('ℹ️ No profile image selected');
        profileImageUrl = null;
      }

// DEBUG: Check what's being saved
      debugPrint('🎯 FINAL - profileImageUrl type: ${profileImageUrl.runtimeType}');
      debugPrint('🎯 FINAL - profileImageUrl is null: ${profileImageUrl == null}');
      if (profileImageUrl != null) {
        debugPrint('🎯 FINAL - profileImageUrl length: ${profileImageUrl.length}');
      }

// Save user data to Firestore
      debugPrint('💾 Saving user data to Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'location': location,
        'farmSize': farmSize,
        'profileImageUrl': profileImageUrl, // This stores the Base64 string
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'uid': uid,
      });
      debugPrint('✅ User data saved with Base64 image');

      // Save user data to Firestore
      debugPrint('Saving user data to Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'location': location,
        'farmSize': farmSize,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'uid': uid, // ← ADD THIS for easier queries
      });

      // Send email verification
      debugPrint('Sending email verification...');
      await user.sendEmailVerification();
      debugPrint('Email verification sent');

      if (mounted) {
        // Save the image to ProfileImageManager
        if (_imageFile != null) {
          ProfileImageManager.setPendingImage(_imageFile!);
          debugPrint('Profile image saved to manager');
        }

        // Show success message with email verification info
        SnackbarUtils.showRegistrationSuccessSnackBar(context);

        // Show additional info about email verification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Account created successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Please check your email ($email) for verification link.', style: TextStyle(fontSize: 12)),
              ],
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 3));

        // Sign out the user after registration to force login
        await FirebaseAuth.instance.signOut();
        debugPrint('User signed out after registration');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      _handleFirebaseAuthError(e);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Firebase error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      SnackbarUtils.showUnexpectedErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }  void _handleFirebaseAuthError(FirebaseAuthException e) {
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

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const RegisterAppBar(),
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
                  // UPDATED: Using the extracted ProfileImageWidget
                  ProfileImageWidget(
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