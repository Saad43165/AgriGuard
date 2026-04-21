import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/login/services/guest_service.dart';

/// Simple language service for guest banner
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

  static String getText(String english, String urdu) {
    return _isUrdu ? urdu : english;
  }
}

/// Enhanced banner widget with bilingual support
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
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _initAnimation();
  }

  Future<void> _loadLanguage() async {
    await GuestBannerLanguage.loadLanguage();
    if (mounted) {
      setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    }
  }

  void _initAnimation() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    await GuestBannerLanguage.toggleLanguage();
    setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    HapticFeedback.lightImpact();
  }

  Color _getBannerColor() {
    final remaining = widget.guestService.remainingScans;
    if (remaining <= 2) return Colors.red.shade500;
    if (remaining <= 5) return Colors.orange.shade500;
    return Colors.blue.shade500;
  }

  IconData _getBannerIcon() {
    final remaining = widget.guestService.remainingScans;
    if (remaining <= 2) return Icons.warning_rounded;
    if (remaining <= 5) return Icons.info_rounded;
    return Icons.account_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.guestService.isGuestMode) return const SizedBox.shrink();

    final remaining = widget.guestService.remainingScans;
    final baseColor = _getBannerColor();

    return ScaleTransition(
      scale: remaining <= 2 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppMeasurements.getResponsivePadding(context) * 0.4,
          vertical: AppMeasurements.getResponsiveSmallPadding(context),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              baseColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(
                AppMeasurements.getResponsiveSmallPadding(context),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getBannerIcon(),
                      color: Colors.white,
                      size: AppMeasurements.getResponsiveIconSizeSmall(context),
                    ),
                  ),

                  SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                GuestBannerLanguage.getText(
                                  'Guest Mode',
                                  'مہمان موڈ',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppMeasurements.getResponsiveFontSize(
                                    context,
                                    baseSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Language toggle
                            _buildLanguageToggle(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          GuestBannerLanguage.getText(
                            '$remaining ${remaining == 1 ? 'scan' : 'scans'} remaining',
                            '$remaining ${remaining == 1 ? 'اسکین باقی' : 'اسکینز باقی'}',
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 12,
                            ),
                          ),
                        ),
                        if (remaining <= 5) ...[
                          const SizedBox(height: 4),
                          Text(
                            GuestBannerLanguage.getText(
                              remaining <= 2
                                  ? '⚠️ Sign in to continue scanning'
                                  : '💡 Sign in for unlimited scans',
                              remaining <= 2
                                  ? '⚠️ اسکین جاری رکھنے کے لیے سائن ان کریں'
                                  : '💡 لامحدود اسکینز کے لیے سائن ان کریں',
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 10,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context) * 0.5),

                  // Sign In button
                  _buildSignInButton(),
                ],
              ),
            ),

            // Benefits bar (only show if scans remaining > 5)
            if (remaining > 5) _buildBenefitsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return InkWell(
      onTap: _toggleLanguage,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              _isUrdu ? 'EN' : 'اردو',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
                (route) => false,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.login_rounded,
                size: 14,
                color: _getBannerColor(),
              ),
              const SizedBox(width: 4),
              Text(
                GuestBannerLanguage.getText('Sign In', 'سائن ان'),
                style: TextStyle(
                  color: _getBannerColor(),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBenefit(
            Icons.all_inclusive,
            GuestBannerLanguage.getText('Unlimited', 'لامحدود'),
          ),
          _buildBenefit(
            Icons.history_rounded,
            GuestBannerLanguage.getText('History', 'تاریخ'),
          ),
          _buildBenefit(
            Icons.cloud_upload_rounded,
            GuestBannerLanguage.getText('Sync', 'مطابقت'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Enhanced compact scan counter with bilingual support
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _initAnimation();
  }

  Future<void> _loadLanguage() async {
    await GuestBannerLanguage.loadLanguage();
    if (mounted) {
      setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    }
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    await GuestBannerLanguage.toggleLanguage();
    setState(() => _isUrdu = GuestBannerLanguage.isUrdu);
    HapticFeedback.lightImpact();
  }

  Color _getCounterColor() {
    final remaining = widget.guestService.remainingScans;
    if (remaining <= 2) return Colors.red.shade600;
    if (remaining <= 5) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.guestService.isGuestMode) return const SizedBox.shrink();

    final remaining = widget.guestService.remainingScans;
    final color = _getCounterColor();

    return ScaleTransition(
      scale: remaining <= 2 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: 14,
                color: color,
              ),
            ),

            const SizedBox(width: 8),

            // Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$remaining',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  GuestBannerLanguage.getText(
                    remaining == 1 ? 'scan left' : 'scans left',
                    remaining == 1 ? 'اسکین باقی' : 'اسکینز باقی',
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    height: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Language toggle
            InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}