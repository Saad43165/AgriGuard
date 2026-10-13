import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

const _kAvatarSize = 80.0; // diameter
const _kCoverHeight = 120.0;

class ProfileHeroSection extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> profile;
  final int totalScans, healthyScans, diseasedScans;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;
  final Widget Function() buildAvatarImage;
  final TranslationService t;

  const ProfileHeroSection({
    super.key,
    required this.isDark,
    required this.profile,
    required this.totalScans,
    required this.healthyScans,
    required this.diseasedScans,
    required this.onAvatarTap,
    required this.onEditTap,
    required this.buildAvatarImage,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceBg = isDark ? AppColors.darkSurface : Colors.white;

    final name = profile['name']?.toString().isNotEmpty == true
        ? profile['name'].toString() : 'User';
    final email = profile['email']?.toString() ?? '';
    final location = profile['location']?.toString() ?? '';
    final farmSize = profile['farmSize']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Cover banner ─────────────────────────────────────────────────
        Container(
          height: _kCoverHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: isDark
                  ? [const Color(0xFF1B4332), AppColors.primary, AppColors.secondary]
                  : [AppColors.primary, AppColors.secondary, const Color(0xFF52B788)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _HexPatternPainter())),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.get('ui_profile'),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800, letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); onEditTap(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.pencil, size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                t.get('ui_edit'),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── White content area ────────────────────────────────────────────
        Container(
          color: surfaceBg,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); onAvatarTap(); },
                    child: Stack(
                      children: [
                        Container(
                          width: _kAvatarSize + 6,
                          height: _kAvatarSize + 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: surfaceBg,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 10, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(child: buildAvatarImage()),
                        ),
                        PositionedDirectional(
                          bottom: 2, end: 2,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle,
                              border: Border.all(color: surfaceBg, width: 2),
                            ),
                            child: const Icon(CupertinoIcons.camera_fill, size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: textColor, letterSpacing: -0.3,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(fontSize: 11, color: captionColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Location + farm chips
              if (location.isNotEmpty || farmSize.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    if (location.isNotEmpty)
                      _InfoChip(icon: CupertinoIcons.location_fill, label: location, isDark: isDark),
                    if (farmSize.isNotEmpty)
                      _InfoChip(
                        icon: CupertinoIcons.tree,
                        label: '$farmSize ${t.get('ui_acres')}',
                        isDark: isDark,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Stats row
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    _StatCard(
                      value: '$totalScans',
                      label: t.get('ui_total_scans'),
                      icon: CupertinoIcons.viewfinder,
                      color: AppColors.primary, isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatCard(
                      value: '$healthyScans',
                      label: t.get('ui_healthy'),
                      icon: CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.emerald, isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatCard(
                      value: '$diseasedScans',
                      label: t.get('ui_diseased'),
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      color: AppColors.error, isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: border),
      ],
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.0)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: captionColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 56,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// QuickLinksRow
// ═══════════════════════════════════════════════════════════════════════════
class QuickLinksRow extends StatelessWidget {
  final bool isDark;
  final TranslationService t;
  const QuickLinksRow({super.key, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final links = [
      _QuickLink(
        icon: CupertinoIcons.clock_fill,
        label: t.get('ui_history'),
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.pushNamed(context, AppRoutes.history),
      ),
      _QuickLink(
        icon: CupertinoIcons.question_circle_fill,
        label: t.get('ui_help'),
        color: const Color(0xFF0EA5E9),
        onTap: () => Navigator.pushNamed(context, AppRoutes.help),
      ),
      _QuickLink(
        icon: CupertinoIcons.settings_solid,
        label: t.get('ui_settings'),
        color: AppColors.violet,
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: links.map((link) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); link.onTap(); },
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: link.color.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(link.icon, size: 21, color: link.color),
                ),
                const SizedBox(height: 6),
                Text(
                  link.label,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.color, required this.onTap});
}

// ── Hex pattern painter ───────────────────────────────────────────────────────
class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 36.0;
    const r = 10.0;
    for (double y = -spacing; y < size.height + spacing; y += spacing * 0.87) {
      final offset = (y ~/ (spacing * 0.87)).isOdd ? spacing / 2 : 0.0;
      for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
        _drawHex(canvas, paint, Offset(x, y), r);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 30) * 3.14159265 / 180;
      final px = c.dx + r * _cos(a);
      final py = c.dy + r * _sin(a);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) {
    a = a % (2 * 3.14159265);
    return 1 - (a * a) / 2 + (a * a * a * a) / 24;
  }

  double _sin(double a) {
    a = a % (2 * 3.14159265);
    return a - (a * a * a) / 6 + (a * a * a * a * a) / 120;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
