import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage guest mode functionality
class GuestService extends ChangeNotifier {
  static final GuestService _instance = GuestService._internal();
  factory GuestService() => _instance;
  GuestService._internal();

  static const String _isGuestKey = 'is_guest_mode';
  static const String _scanCountKey = 'guest_scan_count';
  static const int maxGuestScans = 5;

  bool _isGuestMode = false;
  int _guestScanCount = 0;

  bool get isGuestMode => _isGuestMode;
  int get guestScanCount => _guestScanCount;
  int get remainingScans => maxGuestScans - _guestScanCount;
  bool get hasScansRemaining => _guestScanCount < maxGuestScans;

  /// Initialize guest service and load saved state
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool(_isGuestKey) ?? false;
      _guestScanCount = prefs.getInt(_scanCountKey) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing GuestService: $e');
    }
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, true);
      await prefs.setInt(_scanCountKey, 0);
      _isGuestMode = true;
      _guestScanCount = 0;
      notifyListeners();
      debugPrint('✅ Guest mode enabled');
    } catch (e) {
      debugPrint('❌ Error enabling guest mode: $e');
    }
  }

  /// Disable guest mode (when user logs in)
  Future<void> disableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, false);
      await prefs.setInt(_scanCountKey, 0);
      _isGuestMode = false;
      _guestScanCount = 0;
      notifyListeners();
      debugPrint('✅ Guest mode disabled');
    } catch (e) {
      debugPrint('❌ Error disabling guest mode: $e');
    }
  }

  /// Increment scan count for guest users
  Future<bool> incrementScanCount() async {
    if (!_isGuestMode) return true;

    if (_guestScanCount >= maxGuestScans) {
      debugPrint('❌ Guest scan limit reached');
      return false;
    }

    try {
      _guestScanCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_scanCountKey, _guestScanCount);
      notifyListeners();
      debugPrint('📊 Guest scan count: $_guestScanCount/$maxGuestScans');
      return true;
    } catch (e) {
      debugPrint('❌ Error incrementing scan count: $e');
      return false;
    }
  }

  /// Reset guest scan count (for testing or admin purposes)
  Future<void> resetScanCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_scanCountKey, 0);
      _guestScanCount = 0;
      notifyListeners();
      debugPrint('🔄 Guest scan count reset');
    } catch (e) {
      debugPrint('❌ Error resetting scan count: $e');
    }
  }

  /// Check if guest can perform an action
  bool canPerformAction(String action) {
    if (!_isGuestMode) return true;

    // Actions guests CANNOT perform
    const restrictedActions = [
      'view_profile',
      'view_history',
      'share_results',
      'save_results',
      'view_statistics',
      'edit_profile',
      'access_settings',
    ];

    return !restrictedActions.contains(action);
  }

  /// Get restriction message for a specific action
  String getRestrictionMessage(String action) {
    switch (action) {
      case 'view_profile':
        return 'Profile is not available in guest mode. Please sign in to access your profile.';
      case 'view_history':
        return 'Scan history is not available in guest mode. Please sign in to view your scan history.';
      case 'share_results':
        return 'Sharing is not available in guest mode. Please sign in to share your results.';
      case 'save_results':
        return 'Saving results is not available in guest mode. Please sign in to save your scans.';
      case 'scan_limit':
        return 'You have reached the maximum of $maxGuestScans scans in guest mode. Please sign in to continue scanning.';
      default:
        return 'This feature is not available in guest mode. Please sign in to access all features.';
    }
  }
}