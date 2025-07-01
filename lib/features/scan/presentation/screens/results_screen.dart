import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/widgets/severity_indicator.dart';
import '../../../../mock_data/mock_disease.dart';
import '../../../../mock_data/mock_scans.dart';
import '../../../home/presentation/widgets/nav_bar.dart';
import '../../../../core/constants/app_constants.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  // Design constants
  static const double _sectionSpacing = AppMeasurements.defaultPadding;
  static const double _itemSpacing = AppMeasurements.smallPadding;
  static const double _borderRadius = AppMeasurements.borderRadius;
  static const EdgeInsets _cardPadding = EdgeInsets.all(AppMeasurements.defaultPadding);
  static const EdgeInsets _sectionPadding = EdgeInsets.all(AppMeasurements.defaultPadding);

  const ResultsScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _getDiagnosisResult();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: _buildBody(context, theme, result),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFloatingActionButton(context), // Save button
          const SizedBox(height: 16),
          _buildShareFloatingActionButton(context), // Share button moved here
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Text(
                'Analysis Results',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // Back button moved to actions (right side)
        Container(
          margin: const EdgeInsets.only(right: AppMeasurements.smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child:  Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22, // Reduced size
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, DiagnosisResult result) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
            const Color(0xFF0F0F23),
            const Color(0xFF16213E),
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F23),
          ]
              : [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
            Theme.of(context).colorScheme.surface,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: _sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagnosisCard(context, theme, result),
              const SizedBox(height: _sectionSpacing),
              _buildAnalysisDetailsCard(context),
              const SizedBox(height: _sectionSpacing),
              _buildRecommendationsCard(context, result),
              const SizedBox(height: _sectionSpacing),
              if (scanData['imageUrl'] != null) ...[
                _buildScannedImageSection(context),
                const SizedBox(height: _sectionSpacing),
              ],
              _buildNextStepsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context, ThemeData theme, DiagnosisResult result) {
    return _buildGlassCard(
      context,
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLANT DIAGNOSIS',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              result.disease,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: _itemSpacing),
            SeverityIndicator(severity: result.severity),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisDetailsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Analysis Details',
          icon: Icons.analytics_rounded,
        ),
        const SizedBox(height: _itemSpacing),
        _buildGlassCard(
          context,
          child: Padding(
            padding: _cardPadding,
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  label: 'Confidence Level',
                  value: '85%',
                  icon: Icons.assessment_rounded,
                ),
                const SizedBox(height: _itemSpacing),
                _buildDetailRow(
                  context,
                  label: 'Detection Date',
                  value: _formatDate(DateTime.now()),
                  icon: Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, DiagnosisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Treatment Recommendations',
          icon: Icons.medical_services_rounded,
        ),
        const SizedBox(height: _itemSpacing),
        _buildGlassCard(
          context,
          child: Column(
            children: result.recommendations.asMap().entries.map((entry) {
              final isLast = entry.key == result.recommendations.length - 1;
              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Scanned Image',
          icon: Icons.photo_camera_rounded,
        ),
        const SizedBox(height: _itemSpacing),
        _buildGlassCard(
          context,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Image.file(
              File(scanData['imageUrl'] as String),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Next Steps',
          icon: Icons.next_plan_rounded,
        ),
        const SizedBox(height: _itemSpacing),
        _buildGlassCard(
          context,
          child: Padding(
            padding: _cardPadding,
            child: Column(
              children: [
                _buildActionItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Monitor Progress',
                  subtitle: 'Check back in 3-5 days',
                ),
                const SizedBox(height: _itemSpacing),
                _buildActionItem(
                  context,
                  icon: Icons.local_pharmacy_rounded,
                  title: 'Purchase Treatment',
                  subtitle: 'Find recommended products',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _saveReport(context);
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      tooltip: 'Save Report',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.save_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildShareFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _shareResults(context);
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      tooltip: 'Share Results',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.share_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareResults(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing results...'),
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
      ),
    );
  }

  void _saveReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report saved successfully'),
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
      ),
    );
  }

  DiagnosisResult _getDiagnosisResult() {
    if (scanData.isNotEmpty) {
      try {
        final String disease = mockDiseases.isNotEmpty
            ? mockDiseases[0]['name'] as String
            : 'Unknown Disease';
        final String severity = 'Moderate';
        final List<String> recommendations = [
          'Apply recommended pesticide.',
          'Monitor crop daily.',
          'Isolate affected plants if possible.',
          'Maintain proper watering schedule.',
        ];
        return DiagnosisResult(
          disease: disease,
          severity: severity,
          recommendations: recommendations,
        );
      } catch (e) {
        debugPrint('Error processing scanData: $e');
      }
    }

    if (mockScans.isNotEmpty) {
      try {
        final scan = mockScans[0];
        final disease = mockDiseases.firstWhere(
              (d) => d['id'] == scan['disease_id'],
          orElse: () => {'name': 'Unknown Disease'},
        );
        return DiagnosisResult(
          disease: disease['name'] as String? ?? 'Unknown Disease',
          severity: scan['severity'] as String? ?? 'Unknown',
          recommendations: (scan['recommendations'] as List<dynamic>?)?.cast<String>() ?? ['Consult an expert'],
        );
      } catch (e) {
        debugPrint('Error fetching mock scan: $e');
      }
    }

    return DiagnosisResult(
      disease: 'Unknown Disease',
      severity: 'Unknown',
      recommendations: ['Consult an expert for further analysis'],
    );
  }
}

class DiagnosisResult {
  final String disease;
  final String severity;
  final List<String> recommendations;

  DiagnosisResult({
    required this.disease,
    required this.severity,
    required this.recommendations,
  });
}