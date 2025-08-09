import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';

/// A model for FAQ items containing a question and answer.
class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

/// A widget displaying a list of expandable FAQ items.
class FaqCard extends StatelessWidget {
  final double itemSpacing;

  const FaqCard({
    super.key,
    required this.itemSpacing,
  });

  // Sample FAQ data (replace with real data source, e.g., API or file)
  static List<FaqItem> _faqItems = [
    FaqItem(
      question: 'How do I scan a plant for diseases?',
      answer: 'Open the app, tap the scan button, and point your camera at the plant. Ensure good lighting for accurate results.',
    ),
     FaqItem(
      question: 'What types of plants can the app identify?',
      answer: 'The app supports a wide range of plants, including common houseplants, garden plants, and crops. Check the plant database for specifics.',
    ),
     FaqItem(
      question: 'How accurate are the scan results?',
      answer: 'Our AI model provides high accuracy, but results depend on image quality and plant condition. Always consult a professional for critical cases.',
    ),
     FaqItem(
      question: 'Can I save my scan history?',
      answer: 'Yes, all scans are saved in your profile. You can view, delete, or share them from the history section.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        SizedBox(height: itemSpacing),
        _faqItems.isEmpty
            ? GlassCard(
          child: Padding(
            padding: EdgeInsets.all(itemSpacing * 1.5),
            child: Text(
              'No FAQs available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        )
            : Column(
          children: _faqItems.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: itemSpacing / 2),
              child: _buildFaqItem(context, faq, index),
            );
          }).toList(),
        ),
        SizedBox(height: itemSpacing),
        _buildMoreFaqLink(context),
      ],
    );
  }

  /// Builds the section header with title and icon.
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(itemSpacing),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            Icons.question_answer_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: itemSpacing),
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ],
    );
  }

  /// Builds an individual FAQ item with expand/collapse functionality.
  Widget _buildFaqItem(BuildContext context, FaqItem faq, int index) {
    return GlassCard(
      borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(itemSpacing / 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            Icons.question_answer_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
          ),
        ),
        trailing: Icon(
          Icons.expand_more_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        childrenPadding: EdgeInsets.all(itemSpacing),
        onExpansionChanged: (expanded) {
          if (expanded) HapticFeedback.lightImpact();
        },
        children: [
          Text(
            faq.answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a link to a full FAQ page or external resource.
  Widget _buildMoreFaqLink(BuildContext context) {
    return GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Replace with actual navigation or URL launch
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Navigating to full FAQ page...'),
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(itemSpacing * 1.5),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(itemSpacing),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.question_answer_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                  ),
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Text(
                    'Visit our FAQ page for more answers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}