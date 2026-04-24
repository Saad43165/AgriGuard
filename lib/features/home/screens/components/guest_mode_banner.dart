import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_themes.dart';
import '../../../auth/login/services/guest_service.dart';

class GuestBannerLanguage {
  static bool _isUrdu = false;
  static bool get isUrdu => _isUrdu;

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool('guest_banner_urdu') ?? false;
  }

  static Future<void> toggleLanguage() async {
    _isUrdu = !_isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_banner_urdu', _isUrdu);
  }

  static String getText(String english, String urdu) => _isUrdu ? urdu : english;
}

class GuestModeBanner extends StatefulWidget {
  final GuestService guestService;

  const GuestModeBanner({
    super.key,
    required this.guestService,
  });

  @override
  State<GuestModeBanner> createState() => _GuestModeBannerState();
}

class _GuestModeBannerState extends State<GuestModeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadLanguage() async {
    await GuestBannerLanguage.loadLanguage();
    if (mounted) setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    await GuestBannerLanguage.toggleLanguage();
    if (mounted) setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    HapticFeedback.lightImpact();
  }

  _BannerTone _toneForRemaining(int remaining) {
    if (remaining <= 2) return _BannerTone.critical;
    if (remaining <= 5) return _BannerTone.warning;
    return _BannerTone.normal;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.guestService.isGuestMode) return const SizedBox.shrink();

    final remaining = widget.guestService.remainingScans;
    final tone = _toneForRemaining(remaining);
    final isCritical = tone == _BannerTone.critical;
    final colors = _bannerColors(tone);

    final banner = Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppMeasurements.getResponsivePadding(context) * 0.45,
        vertical: AppMeasurements.getResponsiveSmallPadding(context),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.border.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _leftIcon(colors),
              const SizedBox(width: 10),
              Expanded(child: _mainTexts(remaining, colors)),
              const SizedBox(width: 8),
              _langToggle(colors),
              const SizedBox(width: 8),
              _signInButton(colors),
            ],
          ),
          if (remaining > 5) ...[
            const SizedBox(height: 10),
            _benefitsRow(colors),
          ],
        ],
      ),
    );

    return isCritical
        ? ScaleTransition(scale: _pulseAnimation, child: banner)
        : banner;
  }

  Widget _leftIcon(_BannerPalette colors) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.person_outline_rounded, size: 18, color: colors.accent),
    );
  }

  Widget _mainTexts(int remaining, _BannerPalette colors) {
    final title = GuestBannerLanguage.getText('Guest mode', 'مہمان موڈ');
    final scans = GuestBannerLanguage.getText(
      '$remaining ${remaining == 1 ? 'scan left' : 'scans left'}',
      '$remaining ${remaining == 1 ? 'اسکین باقی' : 'اسکینز باقی'}',
    );

    final hint = remaining <= 2
        ? GuestBannerLanguage.getText(
      'Sign in now to continue scanning',
      'اسکین جاری رکھنے کے لیے ابھی سائن ان کریں',
    )
        : GuestBannerLanguage.getText(
      'Sign in for unlimited scans and sync',
      'لامحدود اسکینز اور سنک کے لیے سائن ان کریں',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.title,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          scans,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.body,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.caption,
            fontWeight: FontWeight.w500,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _langToggle(_BannerPalette colors) {
    return InkWell(
      onTap: _toggleLanguage,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        ),
        child: Text(
          _isUrdu ? 'EN' : 'اردو',
          style: TextStyle(
            color: colors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _signInButton(_BannerPalette colors) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          GuestBannerLanguage.getText('Sign in', 'سائن ان'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _benefitsRow(_BannerPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _benefitChip(Icons.all_inclusive_rounded,
              GuestBannerLanguage.getText('Unlimited', 'لامحدود'), colors),
          _benefitChip(Icons.history_rounded,
              GuestBannerLanguage.getText('History', 'تاریخ'), colors),
          _benefitChip(Icons.sync_rounded,
              GuestBannerLanguage.getText('Sync', 'مطابقت'), colors),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label, _BannerPalette colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.body,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  _BannerPalette _bannerColors(_BannerTone tone) {
    switch (tone) {
      case _BannerTone.critical:
        return _BannerPalette(
          bg: const Color(0xFFFFF5F5),
          soft: const Color(0xFFFFE4E6),
          border: const Color(0xFFFECACA),
          accent: const Color(0xFFDC2626),
          title: const Color(0xFF7F1D1D),
          body: const Color(0xFF991B1B),
          caption: const Color(0xFFB91C1C),
        );
      case _BannerTone.warning:
        return _BannerPalette(
          bg: const Color(0xFFFFFBEB),
          soft: const Color(0xFFFEF3C7),
          border: const Color(0xFFFDE68A),
          accent: const Color(0xFFD97706),
          title: const Color(0xFF78350F),
          body: const Color(0xFF92400E),
          caption: const Color(0xFFB45309),
        );
      case _BannerTone.normal:
        return _BannerPalette(
          bg: const Color(0xFFF0FDF4),
          soft: const Color(0xFFDCFCE7),
          border: const Color(0xFFBBF7D0),
          accent: AppColors.primary,
          title: const Color(0xFF14532D),
          body: const Color(0xFF166534),
          caption: const Color(0xFF15803D),
        );
    }
  }
}

enum _BannerTone { normal, warning, critical }

class _BannerPalette {
  final Color bg;
  final Color soft;
  final Color border;
  final Color accent;
  final Color title;
  final Color body;
  final Color caption;

  const _BannerPalette({
    required this.bg,
    required this.soft,
    required this.border,
    required this.accent,
    required this.title,
    required this.body,
    required this.caption,
  });
}

class GuestScanCounter extends StatefulWidget {
  final GuestService guestService;

  const GuestScanCounter({
    super.key,
    required this.guestService,
  });

  @override
  State<GuestScanCounter> createState() => _GuestScanCounterState();
}

class _GuestScanCounterState extends State<GuestScanCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadLanguage() async {
    await GuestBannerLanguage.loadLanguage();
    if (mounted) setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    await GuestBannerLanguage.toggleLanguage();
    if (mounted) setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.guestService.isGuestMode) return const SizedBox.shrink();

    final remaining = widget.guestService.remainingScans;
    final color = remaining <= 2
        ? const Color(0xFFDC2626)
        : remaining <= 5
        ? const Color(0xFFD97706)
        : AppColors.primary;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$remaining',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            GuestBannerLanguage.getText(
              remaining == 1 ? 'scan left' : 'scans left',
              remaining == 1 ? 'اسکین باقی' : 'اسکینز باقی',
            ),
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleLanguage,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _isUrdu ? 'EN' : 'اردو',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return remaining <= 2
        ? ScaleTransition(scale: _pulseAnimation, child: chip)
        : chip;
  }
}