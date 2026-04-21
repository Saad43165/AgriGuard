import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/navbar/presentation/nav_bar.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
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
  // Tab indices: 0=Home, 1=History, 2=AI Chat, 3=Profile
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Clamp to valid range 0-3
    _currentIndex = widget.initialIndex.clamp(0, 3);

    // If openCamera flag is set, open capture screen after first frame
    if (widget.userData?['openCamera'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCaptureScreen();
      });
    }
  }

  void _onTabTapped(int navIndex) {
    if (navIndex == 2) {
      // Camera — directly open CaptureScreen (no dialog)
      _openCaptureScreen();
      return;
    }
    final screenIndex = navIndex <= 1 ? navIndex : navIndex - 1;
    if (_currentIndex == screenIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = screenIndex);
  }

  void _openCaptureScreen({bool startAdvanced = false}) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaptureScreen(startAdvanced: startAdvanced)),
    );
  }

  // Map screen index back to navbar selected index
  int get _navbarSelectedIndex {
    // 0→0, 1→1, 2→3, 3→4
    return _currentIndex < 2 ? _currentIndex : _currentIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // we handle all pops ourselves
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentIndex != 0) {
          // Go to home tab first
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = 0);
        } else {
          // Already on home — exit app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: ConnectivityBanner(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(userData: widget.userData),     // 0 = Home
              const HistoryScreen(),                      // 1 = History
              const ChatbotScreen(),                      // 2 = AI Chat
              ProfileScreen(userData: widget.userData),   // 3 = Profile
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _navbarSelectedIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  // Exit is handled by PopScope — SystemNavigator.pop() called directly
}
