import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' show EmailAuthProvider;

import '../../../../auth_services.dart'; // Your AuthService

class DeleteAccountTile extends StatelessWidget {
  final EdgeInsets? padding;

  const DeleteAccountTile({super.key, this.padding});

  // -----------------------------------------------------------------
  //  MAIN DELETE FLOW – ALWAYS ASK FOR PASSWORD
  // -----------------------------------------------------------------
  Future<void> _handleDelete(BuildContext context) async {
    final auth = authService.value;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. First: Confirm deletion
    final confirm = await _showConfirmDialog(context);
    if (!confirm) return;

    HapticFeedback.heavyImpact();

    // 2. Always: Ask for password (even if not forced)
    final password = await _showPasswordDialog(context, user.email ?? '');
    if (password == null) return; // User canceled

    try {
      // 3. Re-authenticate with password
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      // 4. Now delete
      await auth.deleteAccount();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account deleted permanently.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  // -----------------------------------------------------------------
  //  CONFIRM DIALOG
  // -----------------------------------------------------------------
  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all data. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  // -----------------------------------------------------------------
  //  PASSWORD DIALOG – ALWAYS SHOWN
  // -----------------------------------------------------------------
  Future<String?> _showPasswordDialog(BuildContext context, String email) async {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('To delete your account, please enter your password for $email.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Password required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, passwordCtrl.text);
              }
            },
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  //  ERROR SNACKBAR
  // -----------------------------------------------------------------
  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          ),
          child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        ),
        title: Text(
          'Delete Account',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Permanently remove your account and all data',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        onTap: () => _handleDelete(context),
      ),
    );
  }
}