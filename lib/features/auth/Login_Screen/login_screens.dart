import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_themes.dart';
import '../Forget_Pass_Screen/constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/glass_card.dart';
import 'widgets/header_section.dart';
import 'widgets/login_form.dart';
import '../../../auth_services.dart';

/// Screen for handling user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, ScreenAnimationMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    disposeAnimations();
    super.dispose();
  }

  /// Handles login action.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = authService.value;
      final user = await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (mounted) {
          _showSuccessSnackBar('🎉 Welcome back! Redirecting to home...');
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(AppStrings.invalidCredentials);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = AppStrings.invalidCredentials;
        String errorTitle = 'Login Failed';

        if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password. Please try again.';
          errorTitle = 'Wrong Password';
        } else if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email. Would you like to create one?';
          errorTitle = 'Account Not Found';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
          errorTitle = 'Invalid Email';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This account has been disabled. Please contact support.';
          errorTitle = 'Account Disabled';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many failed attempts. Please try again later.';
          errorTitle = 'Too Many Attempts';
        } else if (e.message?.contains('email verification') ?? false) {
          errorMessage = 'Please verify your email before logging in. Check your inbox.';
          errorTitle = 'Email Not Verified';
        }

        _showDetailedErrorSnackBar(errorTitle, errorMessage, e.code);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Displays a success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 20),
            const SizedBox(width: 8),
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
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Displays an error snackbar with icon
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError, size: 20),
            const SizedBox(width: 8),
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
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a detailed error snackbar with action buttons
  void _showDetailedErrorSnackBar(String title, String message, String errorCode) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onError, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onError.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: _getActionLabel(errorCode),
          textColor: theme.colorScheme.onError,
          onPressed: () => _handleSnackBarAction(errorCode),
        ),
      ),
    );
  }

  /// Returns appropriate action label based on error code
  String _getActionLabel(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Sign Up';
      case 'invalid-email':
        return 'Fix Email';
      case 'too-many-requests':
        return 'Try Later';
      case 'user-disabled':
        return 'Contact Support';
      default:
        return 'Dismiss';
    }
  }

  /// Handles snackbar action button presses
  void _handleSnackBarAction(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        Navigator.pushNamed(context, AppRoutes.register);
        break;
      case 'invalid-email':
        _emailController.clear();
        break;
      case 'user-disabled':
      // Could open support email or URL
        _showInfoSnackBar('Please email support@agriguard.com for assistance');
        break;
      default:
      // Just dismiss for other cases
        break;
    }
  }

  /// Displays an informational snackbar
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays a warning snackbar for validation errors
  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppMeasurements.isLargeScreen(context);
    const padding = AppMeasurements.defaultPadding;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                            AppStrings.welcomeBack,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 28),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppMeasurements.smallPadding),
                          Text(
                            AppStrings.signInSubtitle,
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
                            child: LoginForm(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              onForgotPassword: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, AppRoutes.forgotPassword);
                              },
                            ),
                          ),
                          const SizedBox(height: padding),
                          ActionButton(
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                            label: AppStrings.login,
                            icon: Icons.login_rounded,
                            loadingLabel: 'Signing In...',
                          ),
                          const SizedBox(height: padding),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, AppRoutes.register);
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: '${AppStrings.newFarmer} ',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.createAccount,
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