// lib/core/services/localization_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  bool _isUrdu = false;
  bool get isUrdu => _isUrdu;
  String get currentLanguage => _isUrdu ? 'ur' : 'en';
  String get currentLanguageName => _isUrdu ? 'اردو' : 'English';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool('isUrdu') ?? false;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isUrdu = !_isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUrdu', _isUrdu);
    notifyListeners();
  }

  Future<void> setLanguage(bool isUrdu) async {
    _isUrdu = isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUrdu', _isUrdu);
    notifyListeners();
  }

  // Helper method to get text
  String getText(String english, String urdu) {
    return _isUrdu ? urdu : english;
  }
}