import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import 'constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/app_bar.dart';
import 'widgets/email_form.dart';
import 'widgets/glass_card.dart';
import 'widgets/header_section.dart';
import '/auth_services.dart';

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
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    _authService = authService.value;
  }

  @override
  void dispose() {
    _emailController.dispose();
    disposeAnimations();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  RESET PASSWORD
  // ──────────────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email);

      if (!mounted) return;

      _showSuccess(AppStrings.resetLinkSent);

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _handleError(e);
    } catch (_) {
      if (!mounted) return;
      _showError(AppStrings.errorUnexpected);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  ERROR HANDLING
  // ──────────────────────────────────────────────────────────────
  void _handleError(FirebaseAuthException e) {
    final (title, message, action) = switch (e.code) {
      'user-not-found' => (
      'No Account',
      'No user found with this email.',
      SnackBarAction(
        label: 'Sign Up',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
      ),
      ),
      'invalid-email' => (
      'Invalid Email',
      'Please enter a valid email address.',
      null,
      ),
      'too-many-requests' => (
      'Too Many Tries',
      'Please wait a few minutes before trying again.',
      null,
      ),
      _ => (
      'Reset Failed',
      e.message ?? 'Try again later.',
      null,
      ),
    };

    _showDetailedError(title, message, action);
  }

  // ──────────────────────────────────────────────────────────────
  //  SNACKBARS
  // ──────────────────────────────────────────────────────────────
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    _snack(msg, Theme.of(context).colorScheme.primary, Icons.check_circle),
  );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    _snack(msg, Theme.of(context).colorScheme.error, Icons.error_outline),
  );

  void _showDetailedError(String title, String msg, SnackBarAction? action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onError,
                size: AppMeasurements.getResponsiveIconSizeSmall(context)),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.bold,
                )),
          ]),
          const SizedBox(height: 4),
          Text(msg,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onError.withOpacity(0.9),
              )),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context))),
      duration: const Duration(seconds: 6),
      action: action,
    ));
  }

  SnackBar _snack(String msg, Color bg, IconData icon) => SnackBar(
    content: Row(children: [
      Icon(icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: AppMeasurements.getResponsiveIconSizeSmall(context)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ))),
    ]),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context))),
    duration: const Duration(seconds: 4),
  );

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
            stops: AppColors.gradientStops,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HeaderSection(),
                SizedBox(height: padding),
                Text(
                  AppStrings.resetPassword,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 26),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: smallPadding),
                Text(
                  AppStrings.resetPasswordSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: padding * 1.5),

                // Email Form inside GlassCard
                GlassCard(
                  borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
                  padding: EdgeInsets.all(padding),
                  child: EmailForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    onSubmit: _isLoading ? null : _resetPassword,
                  ),
                ),

                SizedBox(height: padding),

                // Send Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ActionButton(
                    isLoading: _isLoading,
                    onPressed: _resetPassword,
                    label: AppStrings.sendResetLink,
                    icon: Icons.send_rounded,
                    loadingLabel: 'Sending...',
                  ),
                ),

                SizedBox(height: smallPadding),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                        ),
                        children: [
                          const TextSpan(text: 'Remembered your password? '),
                          TextSpan(
                            text: AppStrings.login,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}