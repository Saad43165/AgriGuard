import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/widgets/app_logo.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await authService.value.resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      _snack(_error(e.code), isError: true);
    } catch (_) {
      _snack('Failed to send reset email. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _error(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try later.';
      default: return 'Failed to send reset email.';
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B2B1E)),
          onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
        ),
        title: const Text('Reset Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B2B1E))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _sent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Logo - Centered
          const AppLogo(size: 80, shadow: []),
          const SizedBox(height: 32),
          const Text('Forgot your password?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2B1E), letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text('Enter your email and we\'ll send you a reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.5)),
          const SizedBox(height: 40),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email Address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2B1E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9E9E9E), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.error)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Send Reset Link',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Sign In',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 32),
        const Text('Check your email',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                color: Color(0xFF1B2B1E), letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('We have sent a password reset link to ${_emailCtrl.text.trim()}. Please check your inbox.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF718096), height: 1.6)),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (_) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Back to Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
