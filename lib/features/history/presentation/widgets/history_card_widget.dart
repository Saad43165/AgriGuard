import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/severity_indicator.dart';
import 'history_measurements.dart';
import 'history_theme_config.dart';

/// Individual history card widget
class HistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> scan;
  final int index;
  final VoidCallback onDelete;

  const HistoryCardWidget({
    super.key,
    required this.scan,
    required this.index,
    required this.onDelete,
  });

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown date';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) return 'Just now';
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      }

      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  Map<String, dynamic> _convertScanForNavigation(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    final timestamp = data['originalTimestamp'] ?? data['timestamp'];

    if (timestamp is Timestamp) {
      converted['timestamp'] = timestamp.toDate().toIso8601String();
    } else if (timestamp is DateTime) {
      converted['timestamp'] = timestamp.toIso8601String();
    }

    return converted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardStyle = HistoryThemeConfig.getCardStyle(isDark, colorScheme);

    final diagnosis = scan['diagnosis']?.toString() ?? 'Unknown Disease';
    final severity = scan['severity']?.toString() ?? 'Unknown';
    final confidence = scan['confidence']?.toString() ?? '0';
    final cropType = scan['cropType']?.toString() ?? 'Unknown';
    final plantName = scan['plantName']?.toString() ?? '';
    final timestamp = scan['originalTimestamp'] ?? scan['timestamp'];
    final displayTime = _formatTimestamp(timestamp);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardStyle['backgroundColors'],
        ),
        borderRadius: BorderRadius.circular(HistoryMeasurements.cardBorderRadius),
        border: Border.all(color: cardStyle['borderColor']),
        boxShadow: [
          BoxShadow(
            color: cardStyle['shadowColor'],
            blurRadius: HistoryMeasurements.cardBlurRadius,
            offset: HistoryMeasurements.cardShadowOffset,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final navigableScan = _convertScanForNavigation(scan);
            Navigator.pushNamed(
              context,
              AppRoutes.results,
              arguments: {'scanData': navigableScan},
            );
          },
          borderRadius: BorderRadius.circular(HistoryMeasurements.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(HistoryMeasurements.cardPadding),
            child: Row(
              children: [
                _buildScanImage(context, isDark),
                const SizedBox(width: HistoryMeasurements.contentSpacingExtraLarge),
                Expanded(
                  child: _buildCardContent(
                    context,
                    isDark,
                    colorScheme,
                    diagnosis,
                    severity,
                    confidence,
                    cropType,
                    plantName,
                    displayTime,
                  ),
                ),
                const SizedBox(width: HistoryMeasurements.contentSpacingLarge),
                _buildDeleteButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanImage(BuildContext context, bool isDark) {
    final imagePath = scan['imagePath'] as String?;

    Widget imageWidget;

    if (imagePath == null || imagePath.isEmpty) {
      imageWidget = _buildPlaceholderImage(context, isDark);
    } else {
      final file = File(imagePath);
      if (!file.existsSync()) {
        imageWidget = _buildPlaceholderImage(context, isDark);
      } else {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(HistoryMeasurements.imageBorderRadius),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(context, isDark),
          ),
        );
      }
    }

    return Container(
      width: HistoryMeasurements.imageSize,
      height: HistoryMeasurements.imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HistoryMeasurements.imageBorderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            blurRadius: HistoryMeasurements.imageBlurRadius,
            offset: HistoryMeasurements.imageShadowOffset,
          ),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholderImage(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).colorScheme.secondary.withOpacity(0.15),
          ]
              : [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(HistoryMeasurements.imageBorderRadius),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
              : Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Icon(
        Icons.spa_rounded,
        size: HistoryMeasurements.placeholderIconSize,
        color: isDark
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
            : Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
    );
  }

  Widget _buildCardContent(
      BuildContext context,
      bool isDark,
      ColorScheme colorScheme,
      String diagnosis,
      String severity,
      String confidence,
      String cropType,
      String plantName,
      String displayTime,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Plant Name Badge
        if (plantName.isNotEmpty &&
            plantName != 'Unknown' &&
            plantName != 'Unknown Plant')
          _buildPlantNameBadge(context, isDark, plantName),

        // Disease name
        Text(
          diagnosis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: HistoryMeasurements.titleLineHeight,
            color: HistoryThemeConfig.getTextColor(isDark),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: HistoryMeasurements.contentSpacingMedium),

        // Badges row
        Row(
          children: [
            Flexible(
              child: _buildCropTypeBadge(context, isDark, colorScheme, cropType),
            ),
            const SizedBox(width: HistoryMeasurements.badgeSpacing),
            _buildConfidenceBadge(context, isDark, confidence),
          ],
        ),
        const SizedBox(height: HistoryMeasurements.contentSpacingMedium),

        // Severity indicator
        SeverityIndicator(severity: severity),
        const SizedBox(height: HistoryMeasurements.contentSpacingMedium),

        // Timestamp
        _buildTimestamp(context, isDark, displayTime),
      ],
    );
  }

  Widget _buildPlantNameBadge(BuildContext context, bool isDark, String plantName) {
    final style = HistoryThemeConfig.getPlantNameBadgeStyle(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: HistoryMeasurements.contentSpacingSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HistoryMeasurements.badgeHorizontalPadding,
          vertical: HistoryMeasurements.badgeVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: style['backgroundColor'],
          borderRadius:
          BorderRadius.circular(HistoryMeasurements.badgeBorderRadius),
          border: Border.all(
            color: style['borderColor'],
            width: HistoryMeasurements.badgeBorderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco_rounded,
              size: HistoryMeasurements.plantNameBadgeIconSize,
              color: style['iconColor'],
            ),
            const SizedBox(width: HistoryMeasurements.contentSpacingSmall),
            Flexible(
              child: Text(
                plantName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: style['textColor'],
                  fontWeight: FontWeight.w700,
                  fontSize: HistoryMeasurements.plantNameBadgeFontSize,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropTypeBadge(
      BuildContext context,
      bool isDark,
      ColorScheme colorScheme,
      String cropType,
      ) {
    final style = HistoryThemeConfig.getCropTypeBadgeStyle(isDark, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HistoryMeasurements.badgeHorizontalPadding,
        vertical: HistoryMeasurements.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: style['backgroundColor'],
        borderRadius: BorderRadius.circular(HistoryMeasurements.badgeBorderRadius),
        border: Border.all(
          color: style['borderColor'],
          width: HistoryMeasurements.badgeBorderWidth,
        ),
      ),
      child: Text(
        cropType,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: HistoryMeasurements.cropTypeBadgeFontSize,
          fontWeight: FontWeight.w700,
          color: style['textColor'],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, bool isDark, String confidence) {
    final style = HistoryThemeConfig.getConfidenceBadgeStyle(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HistoryMeasurements.confidenceBadgeHorizontalPadding,
        vertical: HistoryMeasurements.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: style['backgroundColor'],
        borderRadius: BorderRadius.circular(HistoryMeasurements.badgeBorderRadius),
        border: Border.all(
          color: style['borderColor'],
          width: HistoryMeasurements.badgeBorderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: HistoryMeasurements.confidenceBadgeIconSize,
            color: style['iconColor'],
          ),
          const SizedBox(width: 3),
          Text(
            '$confidence%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: HistoryMeasurements.confidenceBadgeFontSize,
              fontWeight: FontWeight.w800,
              color: style['textColor'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isDark, String displayTime) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: HistoryMeasurements.timestampIconSize,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        const SizedBox(width: HistoryMeasurements.contentSpacingSmall),
        Text(
          displayTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: HistoryMeasurements.timestampFontSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.delete_outline_rounded,
        size: HistoryMeasurements.deleteButtonSize,
        color: Theme.of(context).colorScheme.error,
      ),
      onPressed: () {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: HistoryMeasurements.deleteButtonMinWidth,
        minHeight: HistoryMeasurements.deleteButtonMinHeight,
      ),
      tooltip: 'Delete',
    );
  }
}