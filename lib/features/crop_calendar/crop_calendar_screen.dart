import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
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
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'autumn';
    return 'winter';
  }

  String _seasonLabel(TranslationService t) {
    switch (_season) {
      case 'spring': return t.get('season_spring');
      case 'summer': return t.get('season_summer');
      case 'autumn': return t.get('season_autumn');
      default: return t.get('season_winter');
    }
  }

  IconData get _seasonIcon {
    switch (_season) {
      case 'spring': return Icons.local_florist_rounded;
      case 'summer': return Icons.wb_sunny_rounded;
      case 'autumn': return Icons.eco_rounded;
      default: return Icons.ac_unit_rounded;
    }
  }

  Color get _seasonColor {
    switch (_season) {
      case 'spring': return AppColors.success;
      case 'summer': return AppColors.warning;
      case 'autumn': return const Color(0xFFFF6B35);
      default: return AppColors.info;
    }
  }

  List<String> get _seasonRisks {
    switch (_season) {
      case 'spring': return ['Fungal diseases', 'Rust', 'Powdery Mildew', 'Leaf Spot'];
      case 'summer': return ['Bacterial Spot', 'Blight', 'Heat Stress', 'Aphids'];
      case 'autumn': return ['Late Blight', 'Root Rot', 'Downy Mildew', 'Botrytis'];
      default: return ['Powdery Mildew', 'Dormant Pests', 'Frost Damage', 'Crown Rot'];
    }
  }

  // Month-by-month high risk months for each disease category
  Map<String, List<int>> get _monthlyRiskMap => {
    'Fungal': [3, 4, 5, 9, 10],
    'Bacterial': [6, 7, 8],
    'Rust': [3, 4, 5, 10, 11],
    'Blight': [7, 8, 9, 10],
    'Mildew': [4, 5, 6, 9],
  };

  List<String> _getActionChecklist(TranslationService t) {
    final month = _now.month;
    if (month >= 3 && month <= 5) {
      return t.isUrdu ? [
        'احتیاطی فنگسائیڈ اسپرے کریں',
        'نئی نشوونما کا معائنہ کریں',
        'آبپاشی کا نظام چیک کریں',
        'کھاد ڈالنے کا منصوبہ بنائیں',
      ] : [
        'Apply preventive fungicide spray',
        'Inspect new growth for early disease signs',
        'Check irrigation systems before growing season',
        'Plan fertilization schedule',
      ];
    } else if (month >= 6 && month <= 8) {
      return t.isUrdu ? [
        'جڑ میں پانی دیں، پتوں کو گیلا نہ کریں',
        'بیکٹیریل بیماریوں کے لیے تانبے کا اسپرے',
        'گرمی کے تناؤ کی نگرانی کریں',
        'ہفتے میں دو بار کیڑوں کا معائنہ',
      ] : [
        'Water at base, avoid wetting leaves',
        'Apply copper spray for bacterial diseases',
        'Monitor for heat stress symptoms',
        'Scout for insect pests twice weekly',
      ];
    } else if (month >= 9 && month <= 11) {
      return t.isUrdu ? [
        'پہلی ٹھنڈ سے پہلے فصل کاٹیں',
        'گرے ہوئے پتے فوری صاف کریں',
        'لیٹ بلائٹ سے بچاؤ کریں',
        'آبپاشی کم کریں',
      ] : [
        'Harvest before first frost',
        'Clean up fallen leaves promptly',
        'Apply late blight preventives',
        'Reduce irrigation frequency',
      ];
    } else {
      return t.isUrdu ? [
        'پودوں کو ٹھنڈ سے ڈھانپیں',
        'ڈورمنٹ آئل اسپرے کریں',
        'بیمار لکڑی کاٹیں',
        'بہار کے لیے مٹی تیار کریں',
      ] : [
        'Protect plants from frost with covers',
        'Apply dormant oil sprays',
        'Prune diseased wood during dormancy',
        'Prepare soil with compost for spring',
      ];
    }
  }

  String _getWeatherAdvisory(TranslationService t) {
    switch (_season) {
      case 'spring':
        return t.isUrdu
            ? 'بہار میں بارش اور نمی فنگل بیماریوں کو بڑھاتی ہے۔ ہوا کی اچھی گردش یقینی بنائیں اور پتوں کو گیلا ہونے سے بچائیں۔'
            : 'Spring rains and humidity promote fungal diseases. Ensure good air circulation and avoid leaf wetness.';
      case 'summer':
        return t.isUrdu
            ? 'گرمی اور خشکی بیکٹیریل بیماریوں اور کیڑوں کو بڑھاتی ہے۔ باقاعدہ پانی دیں لیکن پتوں کو گیلا نہ کریں۔'
            : 'Heat and drought stress increases bacterial diseases and pest pressure. Water regularly but avoid leaf wetness.';
      case 'autumn':
        return t.isUrdu
            ? 'خزاں میں ٹھنڈک اور نمی لیٹ بلائٹ اور سڑن کا خطرہ بڑھاتی ہے۔ فصل جلد کاٹیں اور ملبہ صاف کریں۔'
            : 'Cool, moist autumn conditions increase late blight and rot risk. Harvest early and clean up debris.';
      default:
        return t.isUrdu
            ? 'سردیوں میں پالا اور ٹھنڈ پودوں کو نقصان پہنچا سکتی ہے۔ پودوں کو ڈھانپیں اور ڈورمنٹ اسپرے کریں۔'
            : 'Winter frost and cold can damage plants. Cover sensitive plants and apply dormant sprays.';
    }
  }

  List<String> _getPreventiveTips(TranslationService t) {
    switch (_season) {
      case 'spring':
        return [
          t.isUrdu ? 'بارش سے پہلے احتیاطی فنگسائیڈ لگائیں' : 'Apply preventive fungicide before rainy periods',
          t.isUrdu ? 'نئی نشوونما کا ہفتہ وار معائنہ کریں' : 'Inspect new growth weekly for early signs',
          t.isUrdu ? 'پودوں کے درمیان ہوا کی اچھی گردش یقینی بنائیں' : 'Ensure good air circulation between plants',
          t.isUrdu ? 'متاثرہ پودوں کے ملبے کو ہٹائیں اور تلف کریں' : 'Remove and destroy infected plant debris',
        ];
      case 'summer':
        return [
          t.isUrdu ? 'پتوں کو گیلا ہونے سے بچانے کے لیے جڑ میں پانی دیں' : 'Water at the base to avoid leaf wetness',
          t.isUrdu ? 'بیکٹیریل بیماریوں کے لیے تانبے پر مبنی اسپرے لگائیں' : 'Apply copper-based sprays for bacterial diseases',
          t.isUrdu ? 'گرمی کے تناؤ کی نگرانی کریں' : 'Monitor for heat stress and provide shade if needed',
          t.isUrdu ? 'ہفتے میں دو بار کیڑوں کا معائنہ کریں' : 'Scout for insect pests twice weekly',
        ];
      case 'autumn':
        return [
          t.isUrdu ? 'سڑن سے بچانے کے لیے پہلی ٹھنڈ سے پہلے فصل کاٹیں' : 'Harvest before first frost to prevent rot',
          t.isUrdu ? 'نم حالات میں لیٹ بلائٹ سے بچاؤ کریں' : 'Apply late blight preventives in humid conditions',
          t.isUrdu ? 'گرے ہوئے پتوں کو فوری صاف کریں' : 'Clean up fallen leaves and debris promptly',
          t.isUrdu ? 'جڑ سڑن سے بچانے کے لیے آبپاشی کم کریں' : 'Reduce irrigation to prevent root rot',
        ];
      default:
        return [
          t.isUrdu ? 'پودوں کو ٹھنڈ سے ڈھانپ کر بچائیں' : 'Protect plants from frost with covers',
          t.isUrdu ? 'سردیوں میں کیڑوں کے لیے ڈورمنٹ آئل اسپرے کریں' : 'Apply dormant oil sprays for overwintering pests',
          t.isUrdu ? 'سکون کے دوران بیمار لکڑی کاٹیں' : 'Prune diseased wood during dormancy',
          t.isUrdu ? 'بہار کی کاشت کے لیے کھاد سے مٹی تیار کریں' : 'Prepare soil with compost for spring planting',
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
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context);
    final seasonLabel = _seasonLabel(t);

    return Scaffold(
      backgroundColor: bg,
      appBar: AgriAppBar(
        title: t.get('crop_calendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuidanceBanner(cardColor, textColor, captionColor, borderColor, t),
          const SizedBox(height: 16),
          _buildSeasonHeader(cardColor, textColor, captionColor, borderColor, t, seasonLabel),
          const SizedBox(height: 16),
          _buildWeatherAdvisory(cardColor, textColor, captionColor, borderColor, t),
          const SizedBox(height: 16),
          _buildActionChecklist(cardColor, textColor, captionColor, borderColor, t),
          const SizedBox(height: 16),
          _buildMonthlyRiskView(cardColor, textColor, captionColor, borderColor, t),
          const SizedBox(height: 16),
          Text('${t.get('disease_risk_this')} $seasonLabel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 12),
          ...AppSpecies.allSpecies.map((s) => _buildPlantRiskCard(
              s, cardColor, textColor, captionColor, borderColor, t)),
          const SizedBox(height: 16),
          _buildPreventiveTipsCard(cardColor, textColor, captionColor, borderColor, t, seasonLabel),
          const SizedBox(height: 16),
          _buildLocationNote(cardColor, textColor, captionColor, borderColor, t),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGuidanceBanner(Color card, Color text, Color caption, Color border, TranslationService t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _seasonColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _seasonColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _seasonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_seasonIcon, color: _seasonColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.get('crop_calendar_guidance'),
                style: TextStyle(fontSize: 13, color: text, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(Color card, Color text, Color caption, Color border,
      TranslationService t, String seasonLabel) {
    final monthNames = t.isUrdu
        ? ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = monthNames[_now.month - 1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _seasonColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _seasonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_seasonIcon, color: _seasonColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthName, style: TextStyle(
                    color: caption, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(seasonLabel, style: TextStyle(
                    color: _seasonColor, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_seasonRisks.length} ${t.get('disease_risks_identified')}',
                    style: TextStyle(color: caption, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAdvisory(Color card, Color text, Color caption, Color border, TranslationService t) {
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
              const Icon(Icons.cloud_rounded, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text(t.get('weather_advisory'), style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_getWeatherAdvisory(t),
              style: TextStyle(fontSize: 13, color: caption, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildActionChecklist(Color card, Color text, Color caption, Color border, TranslationService t) {
    final items = _getActionChecklist(t);
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
              const Icon(Icons.checklist_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(t.get('action_checklist'), style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${entry.key + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ),
                ),
                Expanded(child: Text(entry.value,
                    style: TextStyle(fontSize: 13, color: caption, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMonthlyRiskView(Color card, Color text, Color caption, Color border, TranslationService t) {
    final monthAbbr = t.isUrdu
        ? ['ج', 'ف', 'م', 'ا', 'م', 'ج', 'ج', 'ا', 'س', 'ا', 'ن', 'د']
        : ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

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
              const Icon(Icons.calendar_view_month_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(t.isUrdu ? 'ماہانہ خطرے کا نقشہ' : 'Monthly Risk Map',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 14),
          ..._monthlyRiskMap.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(entry.key,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: caption)),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(12, (i) {
                      final month = i + 1;
                      final isRisk = entry.value.contains(month);
                      final isCurrent = month == _now.month;
                      return Expanded(
                        child: Container(
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isRisk
                                ? AppColors.error.withValues(alpha: isCurrent ? 1.0 : 0.5)
                                : AppColors.success.withValues(alpha: isCurrent ? 0.6 : 0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: isCurrent ? Border.all(color: AppColors.primary, width: 1.5) : null,
                          ),
                          child: Center(
                            child: Text(monthAbbr[i],
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.9))),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(t.isUrdu ? 'زیادہ خطرہ' : 'High Risk',
                  style: TextStyle(fontSize: 11, color: caption)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(t.isUrdu ? 'کم خطرہ' : 'Low Risk',
                  style: TextStyle(fontSize: 11, color: caption)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(t.isUrdu ? 'موجودہ ماہ' : 'Current Month',
                  style: TextStyle(fontSize: 11, color: caption)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlantRiskCard(PlantSpecies species, Color card, Color text,
      Color caption, Color border, TranslationService t) {
    final risk = _getPlantRisk(species);
    final isHigh = risk['level'] == 'HIGH';
    final riskColor = isHigh ? AppColors.error : AppColors.success;
    final riskLabel = isHigh ? t.get('risk_high') : t.get('risk_low');
    final diseaseEn = risk['disease']!;
    final diseaseText = diseaseEn == 'No major risk this season'
        ? t.get('no_major_risk')
        : (t.isUrdu ? t.translateDisease(diseaseEn) : diseaseEn);

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
                Text(t.isUrdu ? species.nameUr : species.nameEn,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 2),
                Text(diseaseText, style: TextStyle(fontSize: 12, color: caption),
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
            child: Text(riskLabel, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: riskColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventiveTipsCard(Color card, Color text, Color caption,
      Color border, TranslationService t, String seasonLabel) {
    final tips = _getPreventiveTips(t);
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
              const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('${t.get('preventive_tips_for')} $seasonLabel', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: const BoxDecoration(
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

  Widget _buildLocationNote(Color card, Color text, Color caption, Color border, TranslationService t) {
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
                Text(t.get('location_based_advice'), style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 4),
                Text(t.get('set_location_profile'),
                    style: TextStyle(fontSize: 12, color: caption, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
