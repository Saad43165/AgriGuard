import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';
import 'contact_row.dart';
import 'section_header.dart';

/// Displays interactive contact information with email, phone, and website links.
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
                  label: 'Website',
                  value: 'Under Development',
                  icon: Icons.web_rounded,
                  itemSpacing: itemSpacing,
                  onTap: () => _showWebsitePlaceholder(context),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open email client'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening email client: $e'),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open phone app'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening phone app: $e'),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
        ),
      );
    }
  }

  /// Shows a placeholder message for the website.
  Future<void> _showWebsitePlaceholder(BuildContext context) async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Website is under development'),
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
      ),
    );
  }
}