import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/widgets/severity_indicator.dart';
import '../../../../mock_data/mock_disease.dart';
import '../../../../mock_data/mock_scans.dart';
import '../../../home/presentation/widgets/nav_bar.dart';
import '../../../../core/constants/app_routes.dart';
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
    final colorScheme = theme.colorScheme.copyWith(
      primary: const Color(0xFF00D4AA),
      secondary: const Color(0xFF6C63FF),
      surface: const Color(0xFF1A1A2E),
      background: const Color(0xFF16213E),
    );
    final result = _getDiagnosisResult();

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: const Color(0xFF00D4AA),
        colorScheme: colorScheme,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: _buildBody(context, theme, colorScheme, result),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
        ).createShader(bounds),
        child: const Text(
          'Analysis Results',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: AppMeasurements.defaultPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.cyan.withOpacity(0.2),
              Colors.purple.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.only(),
              child: Icon(
                AppIcons.back,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
            ),
          ),
        ),
      ),

      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppMeasurements.smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.2),
                Colors.purple.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                _shareResults(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.share_rounded,
                  color: Color(0xFF00D4AA),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme colorScheme, DiagnosisResult result) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F23),
            Color(0xFF16213E),
            Color(0xFF1A1A2E),
            Color(0xFF0F0F23),
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
              _buildDiagnosisCard(theme, colorScheme, result),
              const SizedBox(height: _sectionSpacing),
              _buildAnalysisDetailsCard(context, colorScheme),
              const SizedBox(height: _sectionSpacing),
              _buildRecommendationsCard(context, result, colorScheme),
              const SizedBox(height: _sectionSpacing),
              if (scanData['imageUrl'] != null) ...[
                _buildScannedImageSection(context),
                const SizedBox(height: _sectionSpacing),
              ],
              _buildNextStepsCard(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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

  Widget _buildDiagnosisCard(ThemeData theme, ColorScheme colorScheme, DiagnosisResult result) {
    return _buildGlassCard(
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLANT DIAGNOSIS',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              result.disease,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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

  Widget _buildAnalysisDetailsCard(BuildContext context, ColorScheme colorScheme) {
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

  Widget _buildRecommendationsCard(BuildContext context, DiagnosisResult result, ColorScheme colorScheme) {
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
          child: Column(
            children: result.recommendations.asMap().entries.map((entry) {
              final isLast = entry.key == result.recommendations.length - 1;
              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
                              colorScheme.primary.withOpacity(0.2),
                              colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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

  Widget _buildNextStepsCard(BuildContext context, ColorScheme colorScheme) {
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
          child: Padding(
            padding: _cardPadding,
            child: Column(
              children: [
                _buildActionItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Monitor Progress',
                  subtitle: 'Check back in 3-5 days',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: _itemSpacing),
                _buildActionItem(
                  context,
                  icon: Icons.local_pharmacy_rounded,
                  title: 'Purchase Treatment',
                  subtitle: 'Find recommended products',
                  colorScheme: colorScheme,
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
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.save_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      tooltip: 'Save Report',
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
                const Color(0xFF00D4AA).withOpacity(0.2),
                const Color(0xFF6C63FF).withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
                const Color(0xFF00D4AA).withOpacity(0.2),
                const Color(0xFF6C63FF).withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
        required ColorScheme colorScheme,
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
                color: Colors.white.withOpacity(0.1),
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
                      colorScheme.primary.withOpacity(0.2),
                      colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.5),
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
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
      ),
    );
  }

  void _saveReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report saved successfully'),
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
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