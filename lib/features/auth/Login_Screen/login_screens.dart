import 'package:agriguard_fyp/features/auth/Login_Screen/services/guest_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/widgets/glass_card.dart';
import '../Forget_Pass_Screen/constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/header_section.dart';
import 'widgets/login_form.dart';
import '/auth_services.dart';

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
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    _guestService.initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    disposeAnimations();
    super.dispose();
  }

  /// Handles guest mode login
  Future<void> _handleGuestLogin() async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
            const Text('Guest Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In guest mode, you can:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
            _buildFeatureItem(
              context,
              Icons.check_circle_outline,
              'Capture leaf images (5 scans only)',
              true,
            ),
            _buildFeatureItem(
              context,
              Icons.check_circle_outline,
              'View scan results',
              true,
            ),
            SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
            Text(
              'You will NOT be able to:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
            _buildFeatureItem(
              context,
              Icons.cancel_outlined,
              'View profile',
              false,
            ),
            _buildFeatureItem(
              context,
              Icons.cancel_outlined,
              'Save scan history',
              false,
            ),
            _buildFeatureItem(
              context,
              Icons.cancel_outlined,
              'Share results',
              false,
            ),
            SizedBox(height: AppMeasurements.getResponsivePadding(context)),
            Container(
              padding: EdgeInsets.all(
                AppMeasurements.getResponsiveSmallPadding(context),
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context) * 0.6,
                ),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: AppMeasurements.getResponsiveIconSizeSmall(context),
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                  Expanded(
                    child: Text(
                      'Sign up for unlimited scans and full access!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context) * 0.6,
                ),
              ),
            ),
            child: const Text('Continue as Guest'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _guestService.enableGuestMode();

        if (mounted) {
          HapticFeedback.mediumImpact();
          _showSuccessSnackBar('Welcome! You have 5 free scans.');
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Failed to enter guest mode: $e');
        }
      }
    }
  }

  Widget _buildFeatureItem(
      BuildContext context,
      IconData icon,
      String text,
      bool isAvailable,
      ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppMeasurements.getResponsiveIconSizeSmall(context) * 0.8,
            color: isAvailable ? Colors.green : Colors.red.shade400,
          ),
          SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context) * 0.5),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles login action.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = authService.value;
      final userCredential = await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final user = userCredential;
      if (user != null) {
        // Refresh user state to get latest email verification status
        await FirebaseAuth.instance.currentUser?.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          if (mounted) {
            _showDetailedSnackBar(
              title: 'Email Not Verified',
              message:
              'Please verify your email to log in. Check your inbox or spam folder.',
              errorCode: 'email-not-verified',
            );
            await refreshedUser.sendEmailVerification();
          }
          return;
        }

        // Disable guest mode if user logs in
        await _guestService.disableGuestMode();

        if (mounted) {
          _showSuccessSnackBar('Login successful. Redirecting to home...');
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
                (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Login failed. Please try again.');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Login failed';
        String title = 'Error';
        String errorCode = e.code;
        switch (e.code) {
          case 'user-not-found':
            title = 'User Not Found';
            message =
            'No account found with this email. Would you like to create one?';
            break;
          case 'wrong-password':
            title = 'Incorrect Password';
            message =
            'The password is incorrect. Please try again or reset your password.';
            break;
          case 'invalid-email':
            title = 'Invalid Email';
            message = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            title = 'Account Disabled';
            message = 'This account has been disabled. Contact support.';
            break;
          case 'too-many-requests':
            title = 'Too Many Attempts';
            message = 'Too many login attempts. Please try again later.';
            break;
          default:
            title = 'Login Error';
            message = 'An error occurred: ${e.message}';
        }
        _showDetailedSnackBar(
          title: title,
          message: message,
          errorCode: errorCode,
        );
        debugPrint('FirebaseAuth error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred: $e');
        debugPrint('Login error: $e');
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
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 14,
                  ),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Displays an error snackbar with icon.
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
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 14,
                  ),
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
                SizedBox(
                  width: AppMeasurements.getResponsiveSmallPadding(context),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
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
                color: Theme.of(context).colorScheme.onError.withOpacity(0.9),
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 12,
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
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label:
          errorCode == 'email-not-verified'
              ? 'Resend Email'
              : errorCode == 'user-not-found'
              ? 'Sign Up'
              : errorCode == 'wrong-password'
              ? 'Reset Password'
              : errorCode == 'user-disabled'
              ? 'Contact Support'
              : 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () async {
            if (errorCode == 'email-not-verified') {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                _showSuccessSnackBar(
                  'Verification email resent. Check your inbox or spam folder.',
                );
              } catch (e) {
                _showErrorSnackBar('Failed to resend email: $e');
              }
            } else if (errorCode == 'user-not-found') {
              Navigator.pushNamed(context, AppRoutes.register);
            } else if (errorCode == 'wrong-password') {
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
            } else if (errorCode == 'user-disabled') {
              _showSuccessSnackBar(
                'Please email support@agriguard.com for assistance.',
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

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
            padding: EdgeInsets.all(padding),
            child: applyAnimations(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HeaderSection(),
                  SizedBox(height: padding),
                  Text(
                    AppStrings.welcomeBack,
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
                    AppStrings.signInSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: AppMeasurements.getResponsiveFontSize(
                        context,
                        baseSize: 12,
                      ),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: padding),
                  GlassCard(
                    borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
                    padding: EdgeInsets.all(padding),
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
                  SizedBox(height: padding),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: ActionButton(
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      label: AppStrings.login,
                      icon: Icons.login_rounded,
                      loadingLabel: 'Signing In...',
                    ),
                  ),
                  SizedBox(height: smallPadding * 0.8),

                  // Guest Mode Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGuestLogin,
                      icon: Icon(
                        Icons.person_outline_rounded,
                        size: AppMeasurements.getResponsiveIconSizeSmall(context),
                      ),
                      label: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppMeasurements.getResponsiveFontSize(
                            context,
                            baseSize: 14,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: AppMeasurements.getResponsivePadding(context) * 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppMeasurements.getResponsiveBorderRadius(context),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: smallPadding),
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
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 12,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: AppStrings.createAccount,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: AppMeasurements.getResponsiveFontSize(
                                  context,
                                  baseSize: 12,
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