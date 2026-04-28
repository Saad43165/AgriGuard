import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_themes.dart';
import '../../profile/utils/profile_image_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  File? _imageFile;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked != null && mounted) setState(() => _imageFile = File(picked.path));
    } catch (e) {
      _snack('Failed to pick image', isError: true);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      final user = cred.user;
      if (user == null) throw Exception('User creation failed');

      String? imageUrl;
      if (_imageFile != null && await _imageFile!.exists()) {
        final bytes = await _imageFile!.readAsBytes();
        imageUrl = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'profileImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
      });

      await user.sendEmailVerification();

      if (mounted) {
        if (_imageFile != null) ProfileImageManager.setPendingImage(_imageFile!);
        _showSuccess();
      }
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code), isError: true);
    } catch (e) {
      _snack('Registration failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        icon: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 30),
        title: 'Account Created!',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A verification email has been sent to:',
              style: TextStyle(fontSize: 14, color: AppColors.lightCaption),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _emailCtrl.text.trim(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightOnSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please verify your email before logging in.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AppDialogActions.primary(
            ctx,
            label: 'Go to Login',
            icon: Icons.login_rounded,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password is too weak. Use 6+ characters.';
      default: return 'Registration failed. Please try again.';
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.lightOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightOnSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.add_a_photo_outlined,
                                size: 36, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Profile Photo (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightCaption)),

              const SizedBox(height: 40),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Full Name'),
                  const SizedBox(height: 8),
                  _field(_nameCtrl, 'Enter your full name', Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 20),

                  _label('Email Address'),
                  const SizedBox(height: 8),
                  _field(_emailCtrl, 'Enter your email', Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                  const SizedBox(height: 20),

                  _label('Location (Optional)'),
                  const SizedBox(height: 8),
                  _field(_locationCtrl, 'e.g. Lahore, Pakistan', Icons.location_on_outlined),
                  const SizedBox(height: 20),

                  _label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: _inputDeco('Create a secure password', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF9E9E9E), size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ characters' : null,
                  ),
                  const SizedBox(height: 20),

                  _label('Confirm Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: _inputDeco('Confirm your password', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF9E9E9E), size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create My Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: AppColors.lightCaption, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign In',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B2B1E)));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1B2B1E), fontSize: 14),
      decoration: _inputDeco(hint, icon),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
    filled: true,
    fillColor: const Color(0xFFF9F9F9),
    labelStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
