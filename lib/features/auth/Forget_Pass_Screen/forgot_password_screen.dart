import 'package:agriguard_fyp/features/auth/Forget_Pass_Screen/widgets/app_bar.dart';
import 'package:agriguard_fyp/features/auth/Forget_Pass_Screen/widgets/back_to_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import 'constants/app_colors.dart';
import 'widgets/header_section.dart';
import 'widgets/email_input.dart';
import 'widgets/submit_button.dart';
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
          borderRadius:
          BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context))),
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
        borderRadius:
        BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context))),
    duration: const Duration(seconds: 4),
  );

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Reset Password',
        onBackPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        topPadding: 0,
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
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: padding * 1.2, vertical: padding * 2),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const ForgotPasswordHeader(),
                const SizedBox(height: 48),
                EmailInput(
                  formKey: _formKey,
                  emailController: _emailController,
                ),
                const SizedBox(height: 28),
                SubmitButton(
                  isLoading: _isLoading,
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: 24),
                BackToLogin(
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}