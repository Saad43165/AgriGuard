// lib/features/scan_history/presentation/components/all_scans_dialog_content.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../ResultScreen/presentation/results_screen.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';
import 'delete_confirmation_dialoag_content.dart';

class AllScansDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> recentScans;
  final Function(String) onDeleteScan;
  final Function(Map<String, dynamic>) onShowOptions;
  final String title;

  const AllScansDialogContent({
    super.key,
    required this.recentScans,
    required this.onDeleteScan,
    required this.onShowOptions,
    required this.title,
  });

  @override
  State<AllScansDialogContent> createState() => _AllScansDialogContentState();
}

class _AllScansDialogContentState extends State<AllScansDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  String _filterType = 'all'; // all, healthy, diseased

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredScans {
    var filtered = widget.recentScans.where((scan) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final plantName = (scan['plantName']?.toString() ?? '').toLowerCase();
        final disease = (scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!plantName.contains(query) && !disease.contains(query)) {
          return false;
        }
      }

      // Healthy / Diseased filter
      final diseaseLower = (scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? '').toLowerCase();

      if (_filterType == 'healthy') {
        return diseaseLower.contains('healthy');
      }
      if (_filterType == 'diseased') {
        return !diseaseLower.contains('healthy') && diseaseLower.isNotEmpty;
      }

      return true;
    }).toList();

    // Sort by date - newest first
    filtered.sort((a, b) {
      final aDate = _getDateTime(a['scanDate'] ?? a['timestamp']);
      final bDate = _getDateTime(b['scanDate'] ?? b['timestamp']);
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  DateTime? _getDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    final dt = _getDateTime(timestamp);
    if (dt == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy • HH:mm').format(dt);
  }

  Map<String, dynamic> _convertForNavigation(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Timestamp) {
        final date = value.toDate();
        converted[key] = date.toIso8601String();
        converted['${key}Millis'] = value.millisecondsSinceEpoch;
      } else if (value is DateTime) {
        converted[key] = value.toIso8601String();
        converted['${key}Millis'] = value.millisecondsSinceEpoch;
      } else if (value is Map) {
        converted[key] = _convertForNavigation(Map<String, dynamic>.from(value));
      } else if (value is List) {
        converted[key] = value.map((e) {
          if (e is Map) return _convertForNavigation(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdvancedSection = widget.title.toLowerCase().contains('advanced');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: MediaQuery.of(context).size.width * 0.95,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFF8FAFB)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme, isDark, isAdvancedSection),
          _buildSearchAndFilter(context, theme, isDark),
          _buildStats(context, theme),
          if (_filteredScans.isEmpty)
            _buildEmptyState(context)
          else
            Flexible(child: _buildScansList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark, bool isAdvanced) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdvanced
              ? [Colors.blue.shade600.withOpacity(0.15), Colors.blue.shade400.withOpacity(0.1)]
              : [theme.colorScheme.primary.withOpacity(0.15), theme.colorScheme.secondary.withOpacity(0.1)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdvanced
                    ? [Colors.blue.shade600, Colors.blue.shade400]
                    : [theme.colorScheme.primary, theme.colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isAdvanced ? Colors.blue : theme.colorScheme.primary).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isAdvanced ? Icons.cloud : Icons.history_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.recentScans.length} ${widget.recentScans.length == 1 ? 'scan' : 'scans'} total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by plant or disease...',
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Healthy', 'healthy', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Diseased', 'diseased', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, ThemeData theme) {
    final healthy = widget.recentScans.where((s) {
      final disease = (s['diagnosis']?.toString() ?? s['diseaseName']?.toString() ?? '').toLowerCase();
      return disease.contains('healthy');
    }).length;

    final diseased = widget.recentScans.length - healthy;

    final avgConfidence = widget.recentScans.isEmpty
        ? 0.0
        : widget.recentScans
        .map((s) => double.tryParse(s['confidence']?.toString() ?? '0') ?? 0)
        .reduce((a, b) => a + b) /
        widget.recentScans.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.check_circle, healthy.toString(), 'Healthy', Colors.green, theme),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withOpacity(0.2)),
          _buildStatItem(Icons.warning_amber_rounded, diseased.toString(), 'Diseased', Colors.orange, theme),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withOpacity(0.2)),
          _buildStatItem(
              Icons.analytics_outlined, '${avgConfidence.toInt()}%', 'Avg Conf.', theme.colorScheme.primary, theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildScansList(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: _filteredScans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final scan = _filteredScans[index];
            final String scanId = scan['id']?.toString() ?? 'scan_${DateTime.now().millisecondsSinceEpoch}_$index';
            final navigableScan = _convertForNavigation(scan);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Dismissible(
                key: Key(scanId),
                direction: DismissDirection.endToStart,
                background: _buildDismissBackground(context),
                confirmDismiss: (_) => _showDeleteConfirmation(context),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  widget.onDeleteScan(scanId);
                },
                child: _buildScanTile(context, scan, navigableScan),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withOpacity(0.2),
            theme.colorScheme.error.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 6),
          const Text(
            'Delete',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: DeleteConfirmationDialogContent(
          onConfirm: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(dialogContext, true);
          },
          onCancel: () {
            HapticFeedback.lightImpact();
            Navigator.pop(dialogContext, false);
          },
        ),
      ),
    );
    return confirmed == true;
  }

  Widget _buildScanTile(
      BuildContext context, Map<String, dynamic> scan, Map<String, dynamic> navigableScan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? 'Unknown Diagnosis';
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final timestamp = _formatTimestamp(scan['scanDate'] ?? scan['timestamp']);
    final confidence = double.tryParse(scan['confidence']?.toString() ?? '0') ?? 0.0;
    final isAdvanced = scan['isAdvanced'] == true || scan['scanType'] == 'advanced';
    final isHealthy = title.toLowerCase().contains('healthy');

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openScanDetails(context, scan);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              theme.colorScheme.surface.withOpacity(0.6),
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ]
                : [
              Colors.white,
              isAdvanced ? Colors.blue.shade50.withOpacity(0.5) : theme.colorScheme.surfaceVariant.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdvanced ? Colors.blue.withOpacity(0.4) : theme.colorScheme.outline.withOpacity(0.2),
            width: isAdvanced ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAdvanced ? Colors.blue : theme.colorScheme.primary).withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: _buildScanImageWithBase64(scan, context),
                  ),
                ),
                if (isAdvanced)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plantName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdvanced) const Icon(Icons.cloud, size: 14, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                        color: isHealthy ? Colors.green.shade700 : (isAdvanced ? Colors.blue.shade800 : null),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getConfidenceColor(confidence).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 11, color: _getConfidenceColor(confidence)),
                              const SizedBox(width: 4),
                              Text(
                                '${confidence.toInt()}%',
                                style: TextStyle(
                                  color: _getConfidenceColor(confidence),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAdvanced)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              scan['analysisSource']?.toString() ?? 'Gemini',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onShowOptions(scan);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanImageWithBase64(Map<String, dynamic> scan, BuildContext context) {
    final theme = Theme.of(context);
    final imageBase64 = scan['imageBase64'] as String?;

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageBase64),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(context),
        );
      } catch (e) {
        debugPrint('Base64 image decode error: $e');
      }
    }

    final imagePath = scan['imagePath'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(context),
          );
        }
      } catch (e) {
        debugPrint('Local image load error: $e');
      }
    }

    final imageUrl = scan['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallbackImage(context),
      );
    }

    return _fallbackImage(context);
  }

  Widget _fallbackImage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          color: theme.colorScheme.primary.withOpacity(0.4),
          size: 36,
        ),
      ),
    );
  }

  void _openScanDetails(BuildContext context, Map<String, dynamic> scan) {
    final isAdvanced = scan['isAdvanced'] == true || scan['scanType'] == 'advanced';

    if (isAdvanced) {
      final analysisResult = {
        'source': scan['analysisSource']?.toString() ?? 'Gemini',
        'data': _getAdvancedData(scan),
        'hasDiseaseInfo': scan['advancedData'] != null,
        'success': true,
        'scanId': scan['id'],
      };

      final originalScanData = {
        'imagePath': scan['imagePath'],
        'imageBase64': scan['imageBase64'],
        'imageUrl': scan['imageUrl'],
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'id': scan['id'],
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvancedResultsScreen(
            analysisResult: analysisResult,
            originalScanData: originalScanData,
          ),
        ),
      );
    } else {
      final scanData = {
        ..._convertForNavigation(scan),
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'originalId': scan['id'],
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(scanData: scanData),
        ),
      );
    }
  }

  Map<String, dynamic> _getAdvancedData(Map<String, dynamic> scan) {
    if (scan['advancedData'] != null) {
      try {
        if (scan['advancedData'] is String) {
          return jsonDecode(scan['advancedData'] as String) as Map<String, dynamic>;
        }
        if (scan['advancedData'] is Map) {
          return Map<String, dynamic>.from(scan['advancedData'] as Map);
        }
      } catch (e) {
        debugPrint('Error parsing advancedData: $e');
      }
    }

    // Fallback structure
    return {
      'plantName': scan['plantName'],
      'scientificName': scan['scientificName'],
      'diseaseName': scan['diagnosis'] ?? scan['diseaseName'],
      'severity': scan['severity'],
      'confidence': (double.tryParse(scan['confidence']?.toString() ?? '0') ?? 0).toInt(),
      'symptoms': (scan['symptoms'] is List) ? List<String>.from(scan['symptoms'] as List) : <String>[],
      'remediation': scan['treatment'] != null ? [scan['treatment'].toString()] : <String>[],
      'precautions': (scan['precautions'] is List)
          ? List<String>.from(scan['precautions'] as List)
          : <String>[],
    };
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 85) return const Color(0xFF10B981); // green
    if (confidence >= 65) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFEF4444); // red
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 72,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty ? 'No Results Found' : 'No Scans Yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Your plant scan history will appear here.\nStart by capturing your first plant!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}