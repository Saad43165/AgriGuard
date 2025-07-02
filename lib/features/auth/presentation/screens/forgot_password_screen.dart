import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/animation_mixin.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin, ScreenAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    disposeAnimations();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await Future.delayed(const Duration(seconds: 1));

      if (email == 'test@agriguard.com') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset link sent to your email',
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
        Navigator.pop(context);
      } else {
        throw Exception('No account found with this email');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('No account') ? 'No account found with this email' : 'An unexpected error occurred',
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

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
            'Reset Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: smallPadding),
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
        ],
        centerTitle: false, // Ensure title stays on the left
      ),      body: Container(
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
                              Container(
                                padding: EdgeInsets.all(smallPadding),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(0.2),
                                      theme.colorScheme.secondary.withOpacity(0.2),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.eco_rounded,
                                  size: AppMeasurements.getResponsiveIconSizeLarge(context),
                                  color: theme.colorScheme.primary,
                                  semanticLabel: 'AgriGuard Logo',
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
                                'Recover your account',
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
                            'Reset Password',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 28),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: smallPadding),
                          Text(
                            'Enter your email to receive a password reset link',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: padding),
                          _buildGlassCard(
                            context,
                            borderRadius: borderRadius,
                            padding: EdgeInsets.all(padding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Address',
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
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: padding),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(borderRadius),
                              onTap: _isLoading ? null : _resetPassword,
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
                                      'Sending...',
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
                                      Icons.send_rounded,
                                      size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    SizedBox(width: smallPadding),
                                    Text(
                                      'Send Reset Link',
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
                                Navigator.pop(context);
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Remembered your password? ',
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