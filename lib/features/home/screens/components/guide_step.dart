import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideLanguageService {
  static bool _isUrdu = false;
  static bool get isUrdu => _isUrdu;

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool('guide_language_urdu') ?? false;
  }

  static Future<void> toggleLanguage() async {
    _isUrdu = !_isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_language_urdu', _isUrdu);
  }
}

class GuideStepCompact extends StatefulWidget {
  final int stepNumber;
  final IconData icon;
  final String title;
  final String titleUrdu;
  final String description;
  final String descriptionUrdu;
  final bool isCompleted;
  final bool isActive;
  final bool showConnector;
  final List<String>? detailPoints;
  final List<String>? detailPointsUrdu;
  final VoidCallback? onTap;

  const GuideStepCompact({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.titleUrdu,
    required this.description,
    required this.descriptionUrdu,
    this.isCompleted = false,
    this.isActive = false,
    this.showConnector = true,
    this.detailPoints,
    this.detailPointsUrdu,
    this.onTap,
  });

  @override
  State<GuideStepCompact> createState() => _GuideStepCompactState();
}

class _GuideStepCompactState extends State<GuideStepCompact>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isExpanded = false;
  bool _showUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  Future<void> _loadLanguage() async {
    await GuideLanguageService.loadLanguage();
    if (mounted) setState(() => _showUrdu = GuideLanguageService.isUrdu);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    await GuideLanguageService.toggleLanguage();
    setState(() => _showUrdu = GuideLanguageService.isUrdu);
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E).withValues(alpha: 0.6)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  width: 1.5,
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE0E0E0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.03 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildIndicator(primaryColor, secondaryColor, isDark),
                      const SizedBox(width: 10),
                      Expanded(child: _buildContent(primaryColor, secondaryColor, isDark)),
                      _buildActions(primaryColor, secondaryColor),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    _buildExpandedContent(primaryColor, secondaryColor, isDark),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.showConnector) _buildConnector(isDark, primaryColor, secondaryColor),
      ],
    );
  }

  Widget _buildIndicator(Color primaryColor, Color secondaryColor, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isCompleted
              ? [primaryColor, secondaryColor]
              : [
            primaryColor.withValues(alpha: 0.2),
            secondaryColor.withValues(alpha: 0.2),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: widget.isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [primaryColor, secondaryColor],
          ).createShader(bounds),
          child: Icon(widget.icon, size: 20),
        ),
      ),
    );
  }

  Widget _buildContent(Color primaryColor, Color secondaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.2),
                    secondaryColor.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'STEP ${widget.stepNumber}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (widget.isCompleted) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 9),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Title - Solid color in light mode, gradient in dark mode
        Text(
          _showUrdu ? widget.titleUrdu : widget.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: isDark ? null : primaryColor,
            foreground: isDark
                ? (Paint()
              ..shader = LinearGradient(
                colors: [primaryColor, secondaryColor],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)))
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _showUrdu ? widget.descriptionUrdu : widget.description,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActions(Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggleLanguage,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  secondaryColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 11, color: primaryColor),
                const SizedBox(width: 3),
                Text(
                  _showUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedRotation(
          duration: const Duration(milliseconds: 250),
          turns: _isExpanded ? 0.5 : 0,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [primaryColor, secondaryColor],
            ).createShader(bounds),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(Color primaryColor, Color secondaryColor, bool isDark) {
    final points = _showUrdu
        ? (widget.detailPointsUrdu ?? widget.detailPoints!)
        : widget.detailPoints!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.08),
            secondaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: primaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                _showUrdu ? 'نکات' : 'Quick Tips',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...points.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.7),
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      margin: const EdgeInsets.only(left: 18),
      width: 2,
      height: 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isCompleted
              ? [primaryColor, secondaryColor.withValues(alpha: 0.3)]
              : [
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}