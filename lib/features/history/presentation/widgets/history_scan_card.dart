import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
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

  // Image widget builder
  Widget _buildImageWidget(double size) {
    // 1. Try base64 image first
    final imageBase64 = scan['imageBase64']?.toString();
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(size),
          ),
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        // Fall through to other methods
      }
    }

    // 2. Try local image path
    final imagePath = scan['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(size),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading local image: $e');
      }
    }

    // 3. Try network URL
    final imageUrl = scan['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
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
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(size),
        ),
      );
    }

    // 4. Fallback to placeholder
    return _buildImagePlaceholder(size);
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: size * 0.3,
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final diagnosis = scan['diagnosis']?.toString() ?? 'Unknown';
    final severity = scan['severity']?.toString() ?? 'Medium';
    final confidence = scan['confidence']?.toString() ?? '0';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: _isAdvanced
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: _isAdvanced ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Compact layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: _buildImageWidget(50),
                    ),

                    SizedBox(width: 12),

                    // Main content - more compact
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row: Plant name and confidence
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        plantName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_isAdvanced)
                                      Container(
                                        margin: EdgeInsets.only(left: 6),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'AI',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(severity)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _getSeverityColor(severity)
                                        .withOpacity(0.3),
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

                          SizedBox(height: 2),

                          // Second row: Scan type and timestamp
                          Row(
                            children: [
                              Text(
                                _isAdvanced
                                    ? (scan['analysisSource']?.toString() ??
                                    'Gemini AI')
                                    : 'On-Device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 4,
                                color:
                                theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(
                                      scan['timestamp'] ?? scan['scanDate']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),

                // Diagnosis row - more compact
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                          theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 16,
                              color: _getSeverityColor(severity),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                diagnosis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity)
                                    .withOpacity(0.15),
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

                    // Delete button - positioned at end of diagnosis row
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.error.withOpacity(0.7),
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
        final now = DateTime.now();
        final diff = now.difference(dt);

        if (diff.inDays == 0) return 'Today';
        if (diff.inDays == 1) return 'Yesterday';
        if (diff.inDays < 7) return '${diff.inDays} days ago';
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    return 'Invalid';
  }
}