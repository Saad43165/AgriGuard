// lib/features/support/widgets/contact_info_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/translation_service.dart';

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translation.get('get_in_touch'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translation.get('help_questions'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        _buildContactItem(
          context,
          translation,
          icon: Icons.email_rounded,
          labelKey: 'email',
          value: 'agriguardsupport@gmail.com',
          color: const Color(0xFF0EA5E9),
          onTap: () => _launchEmail(context, 'agriguardsupport@gmail.com'),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          context,
          translation,
          icon: Icons.phone_rounded,
          labelKey: 'phone',
          value: '+92 341 4279749',
          color: const Color(0xFF10B981),
          onTap: () => _launchPhone(context, '+923414279749'),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          context,
          translation,
          icon: Icons.camera_alt_rounded,
          labelKey: 'instagram',
          value: '@agriguard',
          color: const Color(0xFFE4405F),
          onTap: () => _launchSocial(
            context,
            'https://www.instagram.com/yourprofile',
          ),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildContactItem(
      BuildContext context,
      TranslationService translation, {
        required IconData icon,
        required String labelKey,
        required String value,
        required Color color,
        required VoidCallback onTap,
        required bool isDark,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation.get(labelKey),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    HapticFeedback.lightImpact();
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    HapticFeedback.lightImpact();
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSocial(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    HapticFeedback.lightImpact();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}