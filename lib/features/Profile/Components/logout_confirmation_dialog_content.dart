import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_themes.dart';

void showLogoutConfirmationDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AppDialog(
      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
      title: 'Logout?',
      content: const Text('Are you sure you want to logout from your account?'),
      actions: [
        AppDialogActions.secondary(ctx, label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx);
            onConfirm();
          },
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
