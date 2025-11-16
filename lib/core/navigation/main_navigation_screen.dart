// lib/core/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/Navbar/presentation/nav_bar.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/capture/presentations/capture_screen.dart';
import '../../features/Profile/presentation/profile_screen.dart';


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

  // CRITICAL: Store the body widgets to prevent rebuilding
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize screens ONCE
    _screens = [
      HomeScreen(userData: widget.userData),
      const CaptureScreen(),
      ProfileScreen(userData: widget.userData),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index || _isAnimating) return;

    HapticFeedback.lightImpact();

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
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (mounted) {
              setState(() => _currentIndex = index);
            }
          },
          children: _screens, // Use pre-built screens
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
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}