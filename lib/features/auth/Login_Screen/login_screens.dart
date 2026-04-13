import 'package:agriguard_fyp/features/auth/Login_Screen/services/guest_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../Forget_Pass_Screen/constants/app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/header_section.dart';
import 'widgets/login_form.dart';
import 'widgets/guest_mode_button.dart';
import 'widgets/signup_link.dart';
import '/auth_services.dart';

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
        await FirebaseAuth.instance.currentUser?.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && !refreshedUser.emailVerified) {
          if (mounted) {
            _showDetailedSnackBar(
              title: 'Email Not Verified',
              message: 'Please verify your email to log in. Check your inbox or spam folder.',
              errorCode: 'email-not-verified',
            );
            await refreshedUser.sendEmailVerification();
          }
          return;
        }
        await _guestService.disableGuestMode();
        if (mounted) {
          _showSuccessSnackBar('Login successful. Redirecting...');
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        }
      } else {
        if (mounted) _showErrorSnackBar('Login failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Login failed';
        String title = 'Error';
        String errorCode = e.code;
        switch (e.code) {
          case 'user-not-found':
            title = 'User Not Found';
            message = 'No account found with this email. Would you like to create one?';
            break;
          case 'wrong-password':
            title = 'Incorrect Password';
            message = 'The password is incorrect. Please try again or reset your password.';
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
        _showDetailedSnackBar(title: title, message: message, errorCode: errorCode);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildGuestDialog(),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await _guestService.enableGuestMode();
        if (mounted) {
          HapticFeedback.mediumImpact();
          _showSuccessSnackBar('Welcome! You have 5 free scans.');
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Failed to enter guest mode: $e');
        }
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final auth = authService.value;
      final user = await auth.signInWithGoogle();
      if (user == null) return;
      await _guestService.disableGuestMode();
      if (!mounted) return;
      _showSuccessSnackBar('Signed in with Google. Redirecting...');
      await Future.delayed(const Duration(milliseconds: 900));
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'or continue with',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.15))),
        ],
      ),
    );
  }

  Widget _buildSocialRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleGoogleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Image.asset('assets/images/google_g.png', width: 18, height: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Google',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleGuestLogin,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Guest',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          const Text('Guest Mode'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In guest mode, you can:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.check_circle_outline, 'Capture leaf images (5 scans only)', true),
            _buildFeatureItem(Icons.check_circle_outline, 'View scan results', true),
            const SizedBox(height: 16),
            Text('You will NOT be able to:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.cancel_outlined, 'View profile', false),
            _buildFeatureItem(Icons.cancel_outlined, 'Save scan history', false),
            _buildFeatureItem(Icons.cancel_outlined, 'Share results', false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Continue as Guest'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isAvailable ? Colors.green : Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.onError, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            Text(message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.9),
                )),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context))),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: errorCode == 'email-not-verified'
              ? 'Resend Email'
              : errorCode == 'user-not-found'
              ? 'Sign Up'
              : errorCode == 'wrong-password'
              ? 'Reset Password'
              : 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () async {
            if (errorCode == 'email-not-verified') {
              try {
                await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                _showSuccessSnackBar('Verification email resent.');
              } catch (e) {
                _showErrorSnackBar('Failed to resend email: $e');
              }
            } else if (errorCode == 'user-not-found') {
              Navigator.pushNamed(context, AppRoutes.register);
            } else if (errorCode == 'wrong-password') {
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final isDark = ThemeProvider.of(context).isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? AuthAppColors.darkGradient : AuthAppColors.lightGradient,
            stops: AuthAppColors.gradientStops,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding * 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top breathing room — absorbs leftover space above header
                const Spacer(flex: 2),

                // ── Logo + title ──
                const LoginHeader(),

                // ── Fixed gap: header → fields (tight) ──
                const SizedBox(height: 20),

                // ── Email + password + forgot password ──
                LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onForgotPassword: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                  },
                ),

                // ── Sign In button — sits right below form ──
                const SizedBox(height: 14),
                ActionButton(
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                  label: 'Sign In',
                  icon: Icons.login_rounded,
                  loadingLabel: 'Signing In...',
                ),

                // ── Divider ──
                _buildDivider(),

                // ── Google + Guest side by side ──
                _buildSocialRow(),

                // ── Create account ──
                const SizedBox(height: 10),
                SignUpLink(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                ),

                // Bottom breathing room — mirrors top spacer
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}