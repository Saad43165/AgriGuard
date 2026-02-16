import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _localScanCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalStats();
  }

  Future<void> _loadLocalStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final counts = await _scanDatabase.getScanCounts(user.uid);
        if (mounted) {
          setState(() {
            _localScanCount = counts['total'] ?? 0;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading SQLite scan count: $e');
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
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // Get Firestore data for reports
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final reports = userData?['reportCount'] ?? 0;

            return Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
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

                const SizedBox(height: 12),

                // Stats Row
                if (_isLoading)
                  _buildLoadingStats()
                else
                  Row(
                    children: [
                      // Total Scans (from SQLite)
                      Expanded(
                        child: _buildQuickStat(
                          context,
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scans',
                          value: _localScanCount.toString(),
                          color: const Color(0xFF667eea),
                          isDark: widget.isDark,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Reports (from Firestore)
                      Expanded(
                        child: _buildQuickStat(
                          context,
                          icon: Icons.description_rounded,
                          label: 'Reports',
                          value: reports.toString(),
                          color: const Color(0xFF4CAF50),
                          isDark: widget.isDark,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Member Duration
                      Expanded(
                        child: _buildQuickStat(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: 'Member',
                          value: _getJoinDuration(widget.userProfile['joinDate']),
                          color: const Color(0xFFFF9800),
                          isDark: widget.isDark,
                          isText: true,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
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
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
        bool isText = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isText ? 12 : 18,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getJoinDuration(dynamic joinDate) {
    try {
      if (joinDate == null || joinDate.toString().isEmpty) return '0d';

      DateTime? date;
      if (joinDate is Timestamp) {
        date = joinDate.toDate();
      } else if (joinDate is String) {
        date = DateTime.tryParse(joinDate);
      }

      if (date == null) return '0d';

      final duration = DateTime.now().difference(date);
      if (duration.inDays > 365) {
        return '${(duration.inDays / 365).floor()}y';
      } else if (duration.inDays > 30) {
        return '${(duration.inDays / 30).floor()}mo';
      } else {
        return '${duration.inDays}d';
      }
    } catch (e) {
      return '0d';
    }
  }
}