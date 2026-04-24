import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class HistoryScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryScanCard({
    super.key,
    required this.scan,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  bool get _isAdvanced => scan['isAdvanced'] == true;

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.lightGreen;
      case 'healthy':
      case 'none':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final diagnosis = scan['diagnosis']?.toString() ?? 'Unknown';
    final severity = scan['severity']?.toString() ?? 'Medium';
    final confidence = scan['confidence']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: _isAdvanced
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _isAdvanced ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail — extracted to its own widget
                    ScanThumbnail(
                      imageBase64: scan['imageBase64']?.toString(),
                      imagePath: scan['imagePath']?.toString(),
                      imageUrl: scan['imageUrl']?.toString(),
                      size: 50,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        plantName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_isAdvanced)
                                      Container(
                                        margin:
                                        const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'AI',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(severity)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _getSeverityColor(severity)
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$confidence%',
                                  style: TextStyle(
                                    color: _getSeverityColor(severity),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          Row(
                            children: [
                              Text(
                                _isAdvanced
                                    ? (scan['analysisSource']?.toString() ??
                                    'Groq AI')
                                    : 'On-Device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 4,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(
                                      scan['timestamp'] ?? scan['scanDate']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety,
                                size: 16,
                                color: _getSeverityColor(severity)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                diagnosis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(severity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      DateTime? dt;
      if (date is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(date);
      } else if (date is String) {
        dt = DateTime.tryParse(date);
      } else if (date is DateTime) {
        dt = date;
      }
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inDays == 0) return 'Today';
        if (diff.inDays == 1) return 'Yesterday';
        if (diff.inDays < 7) return '${diff.inDays} days ago';
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    return 'Invalid';
  }
}

// ---------------------------------------------------------------------------
// ScanThumbnail
// Resolves image from base64 → local file → network URL, with a placeholder
// fallback. Extracted from HistoryScanCard so it can be tested independently.
// ---------------------------------------------------------------------------
class ScanThumbnail extends StatelessWidget {
  final String? imageBase64;
  final String? imagePath;
  final String? imageUrl;
  final double size;

  const ScanThumbnail({
    super.key,
    this.imageBase64,
    this.imagePath,
    this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _resolveImage(),
      ),
    );
  }

  Widget _resolveImage() {
    // 1. Base64
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        // fall through
      }
    }

    // 2. Local file
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    // 3. Network URL
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: size * 0.3,
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}