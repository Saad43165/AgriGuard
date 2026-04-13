import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/app_themes.dart';
import '../home/screens/species/plant_species.dart';

class CropCalendarScreen extends StatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  final _now = DateTime.now();

  String get _season {
    final m = _now.month;
    if (m >= 3 && m <= 5) return 'Spring';
    if (m >= 6 && m <= 8) return 'Summer';
    if (m >= 9 && m <= 11) return 'Autumn';
    return 'Winter';
  }

  IconData get _seasonIcon {
    switch (_season) {
      case 'Spring': return Icons.local_florist_rounded;
      case 'Summer': return Icons.wb_sunny_rounded;
      case 'Autumn': return Icons.eco_rounded;
      default: return Icons.ac_unit_rounded;
    }
  }

  Color get _seasonColor {
    switch (_season) {
      case 'Spring': return AppColors.success;
      case 'Summer': return AppColors.warning;
      case 'Autumn': return const Color(0xFFFF6B35);
      default: return AppColors.info;
    }
  }

  List<String> get _seasonRisks {
    switch (_season) {
      case 'Spring': return ['Fungal diseases', 'Rust', 'Powdery Mildew', 'Leaf Spot'];
      case 'Summer': return ['Bacterial Spot', 'Blight', 'Heat Stress', 'Aphids'];
      case 'Autumn': return ['Late Blight', 'Root Rot', 'Downy Mildew', 'Botrytis'];
      default: return ['Powdery Mildew', 'Dormant Pests', 'Frost Damage', 'Crown Rot'];
    }
  }

  List<String> get _preventiveTips {
    switch (_season) {
      case 'Spring':
        return [
          'Apply preventive fungicide before rainy periods',
          'Inspect new growth weekly for early signs',
          'Ensure good air circulation between plants',
          'Remove and destroy infected plant debris',
        ];
      case 'Summer':
        return [
          'Water at the base to avoid leaf wetness',
          'Apply copper-based sprays for bacterial diseases',
          'Monitor for heat stress and provide shade if needed',
          'Scout for insect pests twice weekly',
        ];
      case 'Autumn':
        return [
          'Harvest before first frost to prevent rot',
          'Apply late blight preventives in humid conditions',
          'Clean up fallen leaves and debris promptly',
          'Reduce irrigation to prevent root rot',
        ];
      default:
        return [
          'Protect plants from frost with covers',
          'Apply dormant oil sprays for overwintering pests',
          'Prune diseased wood during dormancy',
          'Prepare soil with compost for spring planting',
        ];
    }
  }

  Map<String, String> _getPlantRisk(PlantSpecies species) {
    final diseases = species.commonDiseasesEn.split(', ');
    final risks = _seasonRisks;
    final matched = diseases.where((d) =>
        risks.any((r) => d.toLowerCase().contains(r.toLowerCase().split(' ').first))).toList();
    if (matched.isNotEmpty) return {'level': 'HIGH', 'disease': matched.first};
    return {'level': 'LOW', 'disease': 'No major risk this season'};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
        ),
        title: Text('Crop Calendar', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Season header
          _buildSeasonHeader(cardColor, textColor, captionColor, borderColor),
          const SizedBox(height: 20),

          // Disease risk cards
          Text('Disease Risk This $_season',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 12),
          ...AppSpecies.allSpecies.map((s) => _buildPlantRiskCard(
              s, cardColor, textColor, captionColor, borderColor)),
          const SizedBox(height: 20),

          // Preventive tips
          _buildPreventiveTips(cardColor, textColor, captionColor, borderColor),
          const SizedBox(height: 20),

          // Location note
          _buildLocationNote(cardColor, textColor, captionColor, borderColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(Color card, Color text, Color caption, Color border) {
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_now.month - 1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_seasonColor.withValues(alpha: 0.8), _seasonColor.withValues(alpha: 0.5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_seasonIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthName, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(_season, style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_seasonRisks.length} disease risks identified',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantRiskCard(PlantSpecies species, Color card, Color text, Color caption, Color border) {
    final risk = _getPlantRisk(species);
    final isHigh = risk['level'] == 'HIGH';
    final riskColor = isHigh ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: species.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(species.nameEn[0], style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: species.color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(species.nameEn, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 2),
                Text(risk['disease']!, style: TextStyle(
                  fontSize: 12, color: caption),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(risk['level']!, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: riskColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventiveTips(Color card, Color text, Color caption, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Preventive Tips for $_season', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 14),
          ..._preventiveTips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                ),
                Expanded(child: Text(tip, style: TextStyle(
                  fontSize: 13, color: caption, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLocationNote(Color card, Color text, Color caption, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location-Based Advice', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 4),
                Text('Set your location in Profile for region-specific disease alerts and seasonal advice.',
                    style: TextStyle(fontSize: 12, color: caption, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
