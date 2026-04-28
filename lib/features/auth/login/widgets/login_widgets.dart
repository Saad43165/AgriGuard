import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

class GuestModeDialog extends StatelessWidget {
  const GuestModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Guest Mode Restrictions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1B2B1E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'You are entering as a guest. Please note the following limitations:',
            style: TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _restrictionItem(Icons.energy_savings_leaf_rounded, '5 Free Scans Available'),
          _restrictionItem(Icons.history_rounded, 'Scan History will NOT be saved'),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Login', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _restrictionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2B1E)))),
        ],
      ),
    );
  }
}

class LoginLabel extends StatelessWidget {
  final String text;
  const LoginLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2B1E)));
}

InputDecoration buildLoginInputDeco(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
  prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
  filled: true,
  fillColor: const Color(0xFFF9F9F9),
  labelStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);
