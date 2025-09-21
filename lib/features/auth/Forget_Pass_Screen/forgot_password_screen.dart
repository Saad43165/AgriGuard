import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Optional, if using Provider
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_themes.dart';
import 'constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/app_bar.dart';
import 'widgets/email_form.dart';
import 'widgets/glass_card.dart';
import 'widgets/header_section.dart';
import '/auth_services.dart'; // Adjusted import path

/// Screen for handling password reset functionality.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin, ScreenAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  late AuthService _authService; // Declare authService as a class variable

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    _authService = authService.value; // Initialize in initState
  }

  @override
  void dispose() {
    _emailController.dispose();
    disposeAnimations();
    super.dispose();
  }

  /// Handles sending a password reset email.
  Future<void> _resetPassword(String email) async {
    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email); // Use the class variable
      if (mounted) {
        _showSnackBar(AppStrings.resetLinkSent);
        Navigator.pop(context); // Return to previous screen after success
      }
    } on Exception catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().contains(AppStrings.noAccountFound)
            ? AppStrings.noAccountFound
            : 'An unexpected error occurred: Please try again');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Displays a snackbar with the given message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppMeasurements.isLargeScreen(context);
    const padding = AppMeasurements.defaultPadding;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: AppStrings.resetPassword,
        onBackPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ThemeProvider.of(context).isDarkMode
                ? AppColors.darkGradient
                : AppColors.lightGradient,
            stops: AppColors.gradientStops,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(padding),
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
                          const HeaderSection(),
                          const SizedBox(height: padding * 2),
                          Text(
                            AppStrings.resetPassword,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 28),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppMeasurements.smallPadding),
                          Text(
                            AppStrings.resetPasswordSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: padding),
                          GlassCard(
                            borderRadius: AppMeasurements.borderRadius,
                            padding: const EdgeInsets.all(padding),
                            child: EmailForm(
                              formKey: _formKey,
                              emailController: _emailController,
                            ),
                          ),
                          const SizedBox(height: padding),
                          ActionButton(
                            isLoading: _isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _resetPassword(_emailController.text.trim());
                              }
                            },
                            label: AppStrings.sendResetLink,
                            icon: Icons.email_rounded,
                            loadingLabel: 'Sending...',
                          ),
                          const SizedBox(height: padding),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Remembered your password? ',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.login,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
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