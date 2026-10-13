import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';
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
  bool _manuallyDismissed = false; // Prevent annoying reappearances
  int _failCount = 0;             
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

    // Initial check after a short delay
    Future.delayed(const Duration(seconds: 3), _checkConnectivity);
    
    // Periodic check every 45 seconds (less aggressive)
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _checkConnectivity());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool online = false;
    try {
      // Double-check with two reliable hosts to avoid DNS flukes
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final result2 = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 3));
        online = result2.isNotEmpty && result2.first.rawAddress.isNotEmpty;
      } catch (_) {
        online = false;
      }
    }

    if (!mounted) return;

    if (!online) {
      _failCount++;
      // Treat as offline after 2 consecutive failed checks (~40s).
      if (_failCount >= 2 && _isOnline) {
        setState(() => _isOnline = false);
        if (!_manuallyDismissed) _showBannerAnimated();
      }
    } else {
      _failCount = 0;
      _manuallyDismissed = false; // Reset dismissal when back online
      if (!_isOnline) {
        setState(() => _isOnline = true);
        _hideBannerAnimated();
      }
    }
  }

  void _showBannerAnimated() {
    if (_showBanner) return;
    setState(() => _showBanner = true);
    _animController.forward();
  }

  void _hideBannerAnimated({bool manual = false}) {
    if (manual) _manuallyDismissed = true;
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
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
            start: 16,
            end: 16,
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
                      Flexible(
                        child: Text(
                          context.read<TranslationService>().get('offline_banner'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _hideBannerAnimated(manual: true),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 16, semanticLabel: 'Dismiss'),
                        ),
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