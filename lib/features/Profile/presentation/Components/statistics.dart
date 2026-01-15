import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/database/scan_database.dart';

class Statistics extends StatefulWidget {
  final EdgeInsets cardPadding;
  final double itemSpacing;
  final String? userId;

  const Statistics({
    super.key,
    required this.cardPadding,
    required this.itemSpacing,
    this.userId,
  });

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
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
      final counts = await _scanDatabase.getScanCounts(user.uid);
      if (mounted) {
        setState(() {
          _localScanCount = counts['total'] ?? 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (_isLoading) {
      return _buildLoadingStats(context);
    }

    if (currentUserId == null) {
      return _buildGuestStats(context);
    }

    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 110,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scans Card - SHOWING SQLITE COUNT
          Expanded(
            child: _StatCard(
              value: _localScanCount.toString(),
              label: 'Scans',
              subtitle: 'Local',
              color: const Color(0xFF9B86F5),
              icon: Icons.scanner_rounded,
              isLoading: false,
            ),
          ),
          SizedBox(width: widget.itemSpacing),

          // Reports Card
          Expanded(
            child: _StatCard(
              value: '0',
              label: 'Reports',
              color: const Color(0xFF4CAF50),
              icon: Icons.description_rounded,
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestStats(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 120,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: '0',
              label: 'Sign in',
              color: Colors.grey,
              icon: Icons.person_outline_rounded,
              isLoading: false,
            ),
          ),
          SizedBox(width: widget.itemSpacing),
          Expanded(
            child: _StatCard(
              value: '0',
              label: 'Sign in',
              color: Colors.grey,
              icon: Icons.person_outline_rounded,
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 120,
      ),
      child: Row(
        children: [
          Expanded(child: _StatCard.loading(context)),
          SizedBox(width: widget.itemSpacing),
          Expanded(child: _StatCard.loading(context)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final bool isLoading;

  const _StatCard({
    required this.value,
    required this.label,
    this.subtitle,
    required this.color,
    required this.icon,
    this.isLoading = false,
  });

  factory _StatCard.loading(BuildContext context) {
    return _StatCard(
      value: '...',
      label: 'Loading',
      color: Colors.grey,
      icon: Icons.refresh_rounded,
      isLoading: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isLoading ? 0.05 : 0.15),
            color.withOpacity(isLoading ? 0.03 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isLoading ? 0.1 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallCard = constraints.maxHeight < 100;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with loading indicator
              Container(
                width: isSmallCard ? 28 : 32,
                height: isSmallCard ? 28 : 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(isLoading ? 0.5 : 1.0),
                      color.withOpacity(isLoading ? 0.3 : 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isLoading ? 0.1 : 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Icon(
                    icon,
                    color: Colors.white,
                    size: isSmallCard ? 14 : 16,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Value and subtitle
              if (isLoading)
                Container(
                  width: 28,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isSmallCard ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: isSmallCard ? 8 : 9,
                            color: color.withOpacity(0.7),
                            height: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 4),

              // Label
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallCard ? 10 : 11,
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(isLoading ? 0.4 : 0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}