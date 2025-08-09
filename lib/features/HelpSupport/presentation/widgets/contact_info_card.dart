import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';
import 'contact_row.dart';
import 'section_header.dart';

/// Displays interactive contact information with email, phone, and social media links.
class ContactInfoCard extends StatelessWidget {
  final double itemSpacing;

  const ContactInfoCard({
    super.key,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Contact Information',
          icon: Icons.info_rounded,
          itemSpacing: itemSpacing,
        ),
        SizedBox(height: itemSpacing),
        GlassCard(
          borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
          child: Padding(
            padding: EdgeInsets.all(itemSpacing * 1.5),
            child: Column(
              children: [
                ContactRow(
                  label: 'Email',
                  value: 'agriguardsupport@gmail.com',
                  icon: Icons.email_rounded,
                  itemSpacing: itemSpacing,
                  onTap: () => _launchEmail(context, 'agriguardsupport@gmail.com'),
                ),
                SizedBox(height: itemSpacing),
                ContactRow(
                  label: 'Phone',
                  value: '+92 341 4279749',
                  icon: Icons.phone_rounded,
                  itemSpacing: itemSpacing,
                  onTap: () => _launchPhone(context, '+923414279749'),
                ),
                SizedBox(height: itemSpacing),
                ContactRow(
                  label: 'Connect With Us',
                  value: 'Instagram',
                  icon: Icons.thumb_up_rounded, // or Icons.camera_alt for Instagram
                  itemSpacing: itemSpacing,
                  onTap: () => _launchSocialMedia(context, 'https://www.instagram.com/yourprofile'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Launches an email client with the specified [email].
  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    HapticFeedback.lightImpact();
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackbar(context, 'Unable to open email client');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error opening email client: $e');
    }
  }

  /// Launches a phone dialer with the specified [phoneNumber].
  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    HapticFeedback.lightImpact();
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackbar(context, 'Unable to open phone app');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error opening phone app: $e');
    }
  }

  /// Launches social media URL
  Future<void> _launchSocialMedia(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    HapticFeedback.lightImpact();
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackbar(context, 'Unable to open social media');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error opening social media: $e');
    }
  }

  /// Shows error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
      ),
    );
  }
}