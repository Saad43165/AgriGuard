import 'package:flutter/material.dart';

class GuideStep extends StatefulWidget {
  final int stepNumber;
  final IconData icon;
  final String title;
  final String titleUrdu;
  final String description;
  final String descriptionUrdu;
  final Color color;
  final bool isCompleted;
  final bool isActive;
  final bool showConnector;
  final List<String>? detailPoints;
  final List<String>? detailPointsUrdu;
  final VoidCallback? onTap;

  const GuideStep({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.titleUrdu,
    required this.description,
    required this.descriptionUrdu,
    required this.color,
    this.isCompleted = false,
    this.isActive = false,
    this.showConnector = true,
    this.detailPoints,
    this.detailPointsUrdu,
    this.onTap,
  });

  @override
  State<GuideStep> createState() => _GuideStepState();
}

class _GuideStepState extends State<GuideStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;
  bool _showUrdu = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.stepNumber * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _toggleLanguage() {
    setState(() => _showUrdu = !_showUrdu);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildCompactStep(isDark),
          if (widget.showConnector) _buildConnector(isDark),
        ],
      ),
    );
  }

  Widget _buildCompactStep(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? LinearGradient(
              colors: [
                widget.color.withOpacity(0.12),
                widget.color.withOpacity(0.05),
              ],
            )
                : null,
            color: widget.isActive
                ? null
                : (isDark
                ? const Color(0xFF2A2A3E).withOpacity(0.5)
                : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive
                  ? widget.color.withOpacity(0.4)
                  : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
              width: 1.5,
            ),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildCompactIndicator(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildContent()),
                  _buildActionIcons(),
                ],
              ),
              if (_isExpanded) _buildExpandedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isCompleted
                  ? [widget.color, widget.color.withOpacity(0.7)]
                  : [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.08)
              ],
            ),
            border: Border.all(
              color: widget.color.withOpacity(widget.isActive ? 0.6 : 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: widget.isCompleted
                ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : Icon(widget.icon,
                color: widget.color, size: 18),
          ),
        ),
        // Pulse effect for active
        if (widget.isActive)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            onEnd: () {
              if (mounted) setState(() {});
            },
            builder: (context, value, _) {
              return Transform.scale(
                scale: 1.0 + (value * 0.25),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(1.0 - value),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.stepNumber}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _showUrdu ? widget.titleUrdu : widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isActive
                      ? widget.color
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _showUrdu ? widget.descriptionUrdu : widget.description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          maxLines: _isExpanded ? null : 1,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language toggle
        InkWell(
          onTap: _toggleLanguage,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _showUrdu
                  ? widget.color.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _showUrdu ? 'EN' : 'اردو',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Expand icon
        AnimatedRotation(
          duration: const Duration(milliseconds: 250),
          turns: _isExpanded ? 0.5 : 0.0,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: widget.color,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (widget.detailPoints == null || widget.detailPoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    final points =
    _showUrdu ? (widget.detailPointsUrdu ?? widget.detailPoints!) : widget.detailPoints!;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_rounded,
                    color: widget.color, size: 14),
                const SizedBox(width: 4),
                Text(
                  _showUrdu ? 'اہم نکات' : 'Tips',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isCompleted
              ? [widget.color, widget.color.withOpacity(0.4)]
              : [
            isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ],
        ),
      ),
    );
  }
}