import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../../../mock_data/mock_disease.dart';
import '../../../../mock_data/mock_scans.dart';
import '../../../home/presentation/widgets/nav_bar.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  // Design constants
  static const double _cardElevation = 2.0;
  static const double _sectionSpacing = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _borderRadius = 12.0;
  static const EdgeInsets _cardPadding = EdgeInsets.all(16);
  static const EdgeInsets _sectionPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  const ResultsScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = _getDiagnosisResult();

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, theme, colorScheme, result),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Analysis Results'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareResults(context),
          tooltip: 'Share Results',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme colorScheme, DiagnosisResult result) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: _sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiagnosisCard(theme, colorScheme, result),
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
    );
  }

  Widget _buildDiagnosisCard(ThemeData theme, ColorScheme colorScheme, DiagnosisResult result) {
    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLANT DIAGNOSIS',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.disease,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
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
          icon: Icons.analytics,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: _cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Padding(
            padding: _cardPadding,
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  label: 'Confidence Level',
                  value: '85%',
                  icon: Icons.assessment,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  context,
                  label: 'Detection Date',
                  value: _formatDate(DateTime.now()),
                  icon: Icons.calendar_today,
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
          icon: Icons.medical_services,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: _cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Column(
            children: [
              ...result.recommendations.map(
                    (rec) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          icon: Icons.photo_camera,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Image.file(
            File(scanData['imageUrl'] as String),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
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
          icon: Icons.next_plan,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: _cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Padding(
            padding: _cardPadding,
            child: Column(
              children: [
                _buildActionItem(
                  context,
                  icon: Icons.history,
                  title: 'Monitor Progress',
                  subtitle: 'Check back in 3-5 days',
                ),
                const Divider(height: 24),
                _buildActionItem(
                  context,
                  icon: Icons.local_pharmacy,
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
      onPressed: () => _saveReport(context),
      tooltip: 'Save Report',
      child: const Icon(Icons.save),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareResults(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing results...')),
    );
  }

  void _saveReport(BuildContext context) {
    // Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved successfully')),
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
          recommendations: (scan['recommendations'] as List<dynamic>?)
              ?.cast<String>() ??
              ['Consult an expert'],
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