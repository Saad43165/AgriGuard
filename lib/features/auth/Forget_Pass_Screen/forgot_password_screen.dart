import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_themes.dart';
import 'constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/app_bar.dart';
import 'widgets/email_form.dart';
import 'widgets/glass_card.dart';
import 'widgets/header_section.dart';
import '/auth_services.dart';

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
  late AuthService _authService;

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

  /// Handles sending a password reset email.
  Future<void> _resetPassword(String email) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        _showSuccessSnackBar(AppStrings.resetLinkSent);
        await Future.delayed(const Duration(milliseconds: 2000));
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Password reset failed';
        String title = 'Error';
        String errorCode = e.code;

        switch (e.code) {
          case 'user-not-found':
            title = 'User Not Found';
            message = 'No account found with this email address.';
            break;
          case 'invalid-email':
            title = 'Invalid Email';
            message = 'Please enter a valid email address.';
            break;
          case 'too-many-requests':
            title = 'Too Many Attempts';
            message = 'Too many reset attempts. Please try again later.';
            break;
          default:
            title = 'Reset Error';
            message = 'An error occurred: ${e.message}';
        }

        _showDetailedSnackBar(
          title: title,
          message: message,
          errorCode: errorCode,
        );
        debugPrint('Password reset error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred: $e');
        debugPrint('Password reset error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Displays a success snackbar.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
            SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays an error snackbar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
            SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a detailed error snackbar with action buttons.
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
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onError,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                ),
                SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onError.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: const Duration(seconds: 6),
        action: _getSnackBarAction(errorCode),
      ),
    );
  }

  SnackBarAction? _getSnackBarAction(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return SnackBarAction(
          label: 'Sign Up',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.register);
          },
        );

      case 'too-many-requests':
        return SnackBarAction(
          label: 'Try Later',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            _showSuccessSnackBar('Please wait 15-30 minutes before trying again.');
          },
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

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
            padding: EdgeInsets.all(padding),
            child: applyAnimations(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HeaderSection(),
                  SizedBox(height: padding),
                  Text(
                    AppStrings.resetPassword,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 24,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: smallPadding),
                  Text(
                    AppStrings.resetPasswordSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 14,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: padding),
                  GlassCard(
                    borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
                    padding: EdgeInsets.all(padding),
                    child: EmailForm(
                      formKey: _formKey,
                      emailController: _emailController,
                    ),
                  ),
                  SizedBox(height: padding),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: ActionButton(
                      isLoading: _isLoading,
                      onPressed: () => _resetPassword(_emailController.text.trim()),
                      label: AppStrings.sendResetLink,
                      icon: Icons.email_rounded,
                      loadingLabel: 'Sending...',
                    ),
                  ),
                  SizedBox(height: smallPadding),
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
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 14,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: AppStrings.login,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: AppMeasurements.getResponsiveFontSize(
                                  context,
                                  baseSize: 14,
                                ),
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
      ),
    );
  }
}