import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageManager {
  static File? _pendingProfileImage;
  static String? _cachedImagePath;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedImagePath = prefs.getString('cached_profile_image_path');
  }

  static void setPendingImage(File? image) {
    _pendingProfileImage = image;
    if (image != null) {
      _cacheImagePath(image.path);
    }
  }

  static File? getPendingImage() {
    // First return any pending image
    if (_pendingProfileImage != null) {
      return _pendingProfileImage;
    }

    // Then try to load from cache
    if (_cachedImagePath != null) {
      final file = File(_cachedImagePath!);
      if (file.existsSync()) {
        _pendingProfileImage = file;
        return file;
      }
    }

    return null;
  }

  static Future<void> _cacheImagePath(String path) async {
    _cachedImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_profile_image_path', path);
  }

  static void clearPendingImage() {
    _pendingProfileImage = null;
    _cachedImagePath = null;
    _clearCachedImagePath();
  }

  static Future<void> _clearCachedImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_profile_image_path');
  }
}