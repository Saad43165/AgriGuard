import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

    _checkConnectivity();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnectivity());
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
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      online = response.statusCode == 200;
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (online != _isOnline) {
      setState(() => _isOnline = online);
      if (!online) {
        setState(() => _showBanner = true);
        _animController.forward();
      } else {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _showBanner = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Stack so the banner overlays content without pushing it down
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            // Place below status bar — doesn't overlap app bar content
            top: MediaQuery.of(context).padding.top + 4,
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
                        blurRadius: 8, offset: const Offset(0, 3),
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
                        onTap: () {
                          _animController.reverse().then((_) {
                            if (mounted) setState(() => _showBanner = false);
                          });
                        },
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
