// lib/core/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/Navbar/presentation/nav_bar.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/capture/presentations/capture_screen.dart';
import '../../features/Profile/presentation/profile_screen.dart';
import '../widgets/app_dialog.dart';
import '../widgets/connectivity_banner.dart';


class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? userData;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.userData,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isAnimating = false;
  late bool _pendingStartOnDevice;
  late bool _pendingStartAdvanced;

  // CRITICAL: Store the body widgets to prevent rebuilding
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _pendingStartOnDevice = widget.userData?['startOnDevice'] == true;
    _pendingStartAdvanced = widget.userData?['startAdvanced'] == true;

    // Initialize screens ONCE
    _screens = [
      HomeScreen(userData: widget.userData),
      CaptureScreen(
        startOnDevice: _pendingStartOnDevice,
        startAdvanced: _pendingStartAdvanced,
      ),
      ProfileScreen(userData: widget.userData),
    ];
    // Consume startup flags once; future tab opens should start at Welcome.
    _pendingStartOnDevice = false;
    _pendingStartAdvanced = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index || _isAnimating) return;

    HapticFeedback.lightImpact();

    // Recreate Capture screen whenever user opens scan tab from navbar,
    // so it always starts from welcome flow.
    if (index == 1) {
      _screens[1] = CaptureScreen(key: UniqueKey());
    }

    setState(() {
      _isAnimating = true;
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          _onTabTapped(0);
        } else if (!didPop && _currentIndex == 0) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: ConnectivityBanner(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentIndex = index);
              }
            },
            children: _screens, // Use pre-built screens
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: const Icon(Icons.exit_to_app_rounded),
        title: 'Exit App',
        content: const Text('Are you sure you want to exit?'),
        actions: [
          AppDialogActions.secondary(
            ctx,
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppDialogActions.primary(
            ctx,
            label: 'Exit',
            icon: Icons.exit_to_app_rounded,
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
    );
  }
}