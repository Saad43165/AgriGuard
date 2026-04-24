import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'app_themes.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _showBanner = false;
  int _failCount = 0;          // require 2 consecutive failures before showing
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Don't check immediately on startup — wait for the first interval
    // to avoid false positives during app boot / Wi-Fi association delay.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkConnectivity());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool online;
    try {
      // DNS lookup is faster, uses no data, and works even when
      // google.com redirects or blocks HTTP (captive portals, etc.)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    if (!mounted) return;

    if (!online) {
      _failCount++;
      // Only treat as truly offline after 2 consecutive failures
      if (_failCount >= 2 && _isOnline) {
        setState(() => _isOnline = false);
        _showBannerAnimated();
      }
    } else {
      _failCount = 0;
      if (!_isOnline) {
        setState(() => _isOnline = true);
        _hideBannerAnimated();
      }
    }
  }

  void _showBannerAnimated() {
    setState(() => _showBanner = true);
    _animController.forward();
  }

  void _hideBannerAnimated() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📡', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'No internet — Advanced features unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _hideBannerAnimated,
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}