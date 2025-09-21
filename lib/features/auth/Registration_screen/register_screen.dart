import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/login_prompt.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_button.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_form.dart';
import 'package:agriguard_fyp/features/auth/Registration_screen/widgets/register_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth_services.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
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
  final TextEditingController _confirmPasswordController = TextEditingController();
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
          message: 'Profile image selected successfully!',
          isError: false,
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar(message: 'Failed to select image', isError: true);
      debugPrint('Image picker error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null) return null;

    try {
      // TODO: Implement Firebase Storage upload here
      // For now, we'll just return a placeholder
      // You'll need to add firebase_storage package and implement actual upload
      print('Image selected: ${_imageFile!.path}');
      return 'https://example.com/profile-image.jpg'; // Replace with actual upload logic
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      final farmSize = _farmSizeController.text.trim();
      final password = _passwordController.text.trim();

      // Upload profile image if selected
      final profileImageUrl = await _uploadProfileImage();

      // 🔹 Call AuthService with profile image
      final user = await authService.value.signUpWithDetails(
        fullName: name,
        email: email,
        password: password,
        phoneNumber: phone,
        location: location,
        farmSize: farmSize,
        profileImageUrl: profileImageUrl, // Pass the image URL
      );

      if (user != null) {
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        if (profileImageUrl != null) {
          await prefs.setString('user_image', profileImageUrl);
        }

        if (!mounted) return;

        _showSnackBar(
          message: '✅ Account created successfully!',
          isError: false,
        );

        // Navigate to home with proper data structure
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'fullName': name,
            'email': email,
            'phoneNumber': phone, // Changed from 'phone' to 'phoneNumber'
            'location': location,
            'farmSize': farmSize, // Remove 'acres' suffix
            'profileImageUrl': profileImageUrl, // Changed from 'imagePath'
            'createdAt': DateTime.now(), // Changed from 'joinDate'
            'scanCount': 0,
            'crops': const [],
          },
        );
      } else {
        _showSnackBar(
          message: '❌ Registration failed. Please try again.',
          isError: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = '❌ Email already registered. Try logging in.';
      } else if (e.code == 'weak-password') {
        errorMessage = '❌ Password is too weak. Use at least 6 characters.';
      } else {
        errorMessage = '❌ ${e.message ?? "Registration failed"}';
      }

      _showSnackBar(message: errorMessage, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        message: e.toString().contains('Failed to save user data')
            ? '❌ Failed to save user data. Check your permissions.'
            : '❌ Unexpected error: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar({required String message, required bool isError}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isError ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        action: isError && message.contains('Email already registered')
            ? SnackBarAction(
          label: 'Login',
          textColor: theme.colorScheme.onPrimary,
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'Create Account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: AppMeasurements.smallPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.isDarkMode
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
              theme.colorScheme.background,
              theme.colorScheme.background.withOpacity(0.9),
              theme.colorScheme.background.withOpacity(0.8),
              theme.colorScheme.background,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: applyAnimations(
              Column(
                children: [
                  RegisterHeader(
                    imageFile: _imageFile,
                    onImagePressed: _pickImage,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 32),
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
                    onConfirmPasswordVisibilityChanged: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  const SizedBox(height: 16),
                  RegisterButton(
                    onPressed: _isLoading ? () {} : _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
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