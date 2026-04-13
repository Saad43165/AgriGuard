import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/scan_database.dart';

class CompactStatistics extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isDark;
  final Animation<double> fadeAnimation;

  const CompactStatistics({
    super.key,
    required this.userProfile,
    required this.isDark,
    required this.fadeAnimation,
  });

  @override
  State<CompactStatistics> createState() => _CompactStatisticsState();
}

class _CompactStatisticsState extends State<CompactStatistics> {
  final ScanDatabase _scanDatabase = ScanDatabase.instance;
  int _totalScans = 0;
  int _healthyScans = 0;
  int _diseasedScans = 0;
  String _memberSince = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Get total scans
        final counts = await _scanDatabase.getScanCounts(user.uid);
        _totalScans = counts['total'] ?? 0;

        // Get all scans to count healthy vs diseased
        final allScans = await _scanDatabase.getAllScans(user.uid);

        int healthy = 0;
        int diseased = 0;

        for (var scan in allScans) {
          final diagnosis = (scan['diagnosis']?.toString() ??
              scan['diseaseName']?.toString() ??
              '').toLowerCase();

          if (diagnosis.contains('healthy') || diagnosis.isEmpty) {
            healthy++;
          } else {
            diseased++;
          }
        }

        _healthyScans = healthy;
        _diseasedScans = diseased;

        // Format member since date
        _memberSince = _formatMemberSince(widget.userProfile['joinDate']);

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatMemberSince(dynamic joinDate) {
    try {
      if (joinDate == null || joinDate.toString().isEmpty) {
        return 'Recently';
      }

      DateTime? date;
      if (joinDate is Timestamp) {
        date = joinDate.toDate();
      } else if (joinDate is String) {
        date = DateTime.tryParse(joinDate);
      }

      if (date == null) return 'Recently';

      return DateFormat('MMM yyyy').format(date);
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDark
                ? [
              const Color(0xFF1E1E2E),
              const Color(0xFF16213E),
            ]
                : [
              Colors.white,
              const Color(0xFFF8F9FF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Member since badge
                if (!_isLoading && _memberSince.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Since $_memberSince',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats Row
            if (_isLoading)
              _buildLoadingStats()
            else
              Row(
                children: [
                  // Total Scans
                  Expanded(
                    child: _buildQuickStat(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Total Scans',
                      value: _totalScans.toString(),
                      color: const Color(0xFF667eea),
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Healthy Plants
                  Expanded(
                    child: _buildQuickStat(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'Healthy',
                      value: _healthyScans.toString(),
                      color: const Color(0xFF10B981),
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Diseased Plants
                  Expanded(
                    child: _buildQuickStat(
                      context,
                      icon: Icons.warning_rounded,
                      label: 'Diseased',
                      value: _diseasedScans.toString(),
                      color: const Color(0xFFFF9800),
                      isDark: widget.isDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        Expanded(child: _buildLoadingCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingCard()),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Loading',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}