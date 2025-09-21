import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';

class StatisticsDialogContent extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const StatisticsDialogContent({
    super.key,
    required this.userProfile,
  });

  @override
  State<StatisticsDialogContent> createState() => _StatisticsDialogContentState();
}

class _StatisticsDialogContentState extends State<StatisticsDialogContent> {
  Map<String, int> _scansPerCrop = {};
  DateTime _lastScanDate = DateTime.now();
  int _totalScans = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserStatistics();
  }

  Future<void> _loadUserStatistics() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Get user's scan count from profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final userData = userDoc.data();
        _totalScans = userData?['scanCount'] ?? 0;

        // Get scan history to calculate crop statistics
        final scansSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('scans')
            .orderBy('timestamp', descending: true)
            .get();

        // Calculate scans per crop
        final scansPerCrop = <String, int>{};
        DateTime lastScan = DateTime.now();

        for (final doc in scansSnapshot.docs) {
          final data = doc.data();
          final cropType = data['cropType'] ?? 'Unknown';
          final timestamp = data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['timestamp'].toString());

          // Update last scan date
          if (timestamp.isAfter(lastScan)) {
            lastScan = timestamp;
          }

          // Count scans per crop
          scansPerCrop.update(cropType, (value) => value + 1, ifAbsent: () => 1);
        }

        setState(() {
          _scansPerCrop = scansPerCrop;
          _lastScanDate = lastScan;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  String _formatScanCount(int count) {
    if (count == 0) return 'No scans';
    if (count == 1) return '1 scan';
    return '$count scans';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormatter = DateFormat('MMMM d, yyyy');

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
      ),
      child: Stack(
        children: [
          GlassCard(
            borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
            blur: isDarkMode ? 15.0 : 10.0,
            child: Padding(
              padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Statistics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                    ),
                  ),
                  SizedBox(height: AppMeasurements.getResponsivePadding(context)),

                  if (_isLoading)
                    _buildLoadingState()
                  else if (_hasError)
                    _buildErrorState()
                  else
                    _buildStatisticsContent(dateFormatter),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppMeasurements.getResponsivePadding(context) / 2,
            top: AppMeasurements.getResponsivePadding(context) / 2,
            child: Semantics(
              label: 'Close dialog',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load statistics',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadUserStatistics,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent(DateFormat dateFormatter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Total scans: $_totalScans',
          child: Text(
            'Total Scans: $_totalScans',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
          ),
        ),
        SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),

        if (_scansPerCrop.isEmpty)
          Semantics(
            label: 'No crop scans available yet',
            child: Text(
              'No crop scans available yet. Start scanning to see statistics!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scans by Crop Type:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
              ..._scansPerCrop.entries.map((entry) => Semantics(
                label: '${entry.key}: ${_formatScanCount(entry.value)}',
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppMeasurements.getResponsiveSmallPadding(context)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppMeasurements.getResponsiveSmallPadding(context),
                      vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCropIcon(entry.key),
                          color: Theme.of(context).colorScheme.primary,
                          size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                        ),
                        SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${_formatScanCount(entry.value)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                            ),
                          ),
                        ),
                        if (entry.value > 0)
                          Text(
                            '${((entry.value / _totalScans) * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),

        if (_totalScans > 0) ...[
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context)),
          Semantics(
            label: 'Last scan date: ${dateFormatter.format(_lastScanDate)}',
            child: Text(
              'Last Scan: ${dateFormatter.format(_lastScanDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],

        SizedBox(height: AppMeasurements.getResponsivePadding(context)),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }

  IconData _getCropIcon(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'wheat':
        return Icons.grass_rounded;
      case 'cotton':
        return Icons.local_florist_rounded;
      case 'rice':
        return Icons.water_drop_rounded;
      case 'corn':
        return Icons.eco_rounded;
      case 'sugarcane':
        return Icons.forest_rounded;
      default:
        return Icons.agriculture_rounded;
    }
  }
}