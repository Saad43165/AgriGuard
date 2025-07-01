import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/animation_mixin.dart';
import '../../../../core/constants/app_measurements.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin, ScreenAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile image selected successfully!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            ),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          ),
        ),
      );
      debugPrint('Image picker error: $e');
    } finally {
      setState(() => _isLoading = false);
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

      await Future.delayed(const Duration(seconds: 1));

      if (email == 'test@agriguard.com') {
        throw Exception('Email already registered');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          'fullName': name,
          'email': email,
          'phone': phone,
          'location': location,
          'farmSize': '$farmSize acres',
          'imagePath': _imageFile?.path,
          'joinDate': 'Joined: ${DateTime.now().toString().split(' ')[0]}',
          'scanCount': 0,
          'crops': const [],
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Email already') ? 'Email already registered' : 'Registration failed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, required double borderRadius, required EdgeInsets padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);
    final imageSize = MediaQuery.of(context).size.width * 0.3; // 20% of screen width

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.only(left: smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
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
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsets.all(smallPadding),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colorScheme.primary,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
                ),
              ),
            ),
          ),
        ),
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
              color: theme.colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
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
            padding: EdgeInsets.all(padding),
            child: applyAnimations(
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = isLargeScreen ? 500.0 : constraints.maxWidth;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: _buildGlassCard(
                                  context,
                                  borderRadius: borderRadius,
                                  padding: EdgeInsets.all(smallPadding),
                                  child: Container(
                                    width: imageSize,
                                    height: imageSize,
                                    child: _imageFile == null
                                        ? Icon(
                                      Icons.person_rounded,
                                      size: imageSize * 0.5,
                                      color: theme.colorScheme.primary,
                                      semanticLabel: 'Profile Image Placeholder',
                                    )
                                        : ClipOval(
                                      child: Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                        width: imageSize,
                                        height: imageSize,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.broken_image_rounded,
                                          size: imageSize * 0.5,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: smallPadding),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'AgriGuard',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 32),
                                  ),
                                  textAlign: TextAlign.center,
                                  semanticsLabel: 'AgriGuard',
                                ),
                              ),
                              SizedBox(height: smallPadding),
                              Text(
                                'Create an account to protect your crops',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          SizedBox(height: padding * 2),
                          Text(
                            'Join AgriGuard',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 28),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: smallPadding),
                          _buildGlassCard(
                            context,
                            borderRadius: borderRadius,
                            padding: EdgeInsets.all(padding),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full Name *',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _nameController,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your full name',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Email Address *',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'your@email.com',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      autofillHints: const [AutofillHints.email],
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Phone Number',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '+92 300 1234567',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.phone_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                                            return 'Please enter a valid phone number';
                                          }
                                        }
                                        return null;
                                      },
                                      autofillHints: const [AutofillHints.telephoneNumber],
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Location',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _locationController,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'e.g., Punjab, Pakistan',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.location_on_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      autofillHints: const [AutofillHints.location],
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Farm Size (acres)',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _farmSizeController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'e.g., 5',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.landscape_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Password *',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            color: theme.colorScheme.primary,
                                            size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      autofillHints: const [AutofillHints.password],
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      'Confirm Password *',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                    SizedBox(height: smallPadding),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Confirm your password',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_rounded,
                                          color: theme.colorScheme.primary,
                                          size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            color: theme.colorScheme.primary,
                                            size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                          ),
                                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                      autofillHints: const [AutofillHints.password],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: padding),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(borderRadius),
                              onTap: _isLoading ? null : _register,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: padding),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(borderRadius),
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                ),
                                child: _isLoading
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: AppMeasurements.getResponsiveIconSizeMedium(context),
                                      height: AppMeasurements.getResponsiveIconSizeMedium(context),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                    SizedBox(width: smallPadding),
                                    Text(
                                      'Registering...',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add_rounded,
                                      size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    SizedBox(width: smallPadding),
                                    Text(
                                      'Register',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: padding),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, '/login');
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Login',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}