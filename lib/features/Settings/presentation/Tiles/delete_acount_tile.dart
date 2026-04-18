import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../auth_services.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_themes.dart';

class DeleteAccountTile extends StatelessWidget {
  final EdgeInsets? padding;

  const DeleteAccountTile({super.key, this.padding});

  Future<void> _handleDelete(BuildContext context) async {
    final auth = authService.value;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await _showConfirmDialog(context);
    if (!confirm) return;

    HapticFeedback.heavyImpact();

    final password = await _showPasswordDialog(context, user.email ?? '');
    if (password == null) return;

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      await auth.deleteAccount();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Account deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String msg = 'Failed to delete account.';
        if (e.code == 'wrong-password') {
          msg = 'Incorrect password. Please try again.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Too many attempts. Try again later.';
        }
        _showError(context, msg);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'An unexpected error occurred.');
      }
    }
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
        title: 'Delete Account?',
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          AppDialogActions.secondary(ctx, label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showPasswordDialog(BuildContext context, String email) async {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          icon: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
          title: 'Confirm Password',
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your password for $email to delete your account',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                      onPressed: () => setState(() => obscureText = !obscureText),
                    ),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Password is required' : null,
                ),
              ],
            ),
          ),
          actions: [
            AppDialogActions.secondary(ctx, label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, passwordCtrl.text);
                }
              },
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () => _handleDelete(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Permanently remove your account and all data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}