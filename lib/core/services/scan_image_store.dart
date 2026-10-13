import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps scan photos as compressed JPEG files in the app's documents folder
/// instead of base64 text inside SQLite. Files survive the OS clearing the
/// camera cache, keep list queries small and make History scroll smoothly.
class ScanImageStore {
  ScanImageStore._();

  static const int _maxSide = 1024;
  static const int _jpegQuality = 80;
  static const String _folder = 'scan_images';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// True if [path] is one of our managed copies (safe to delete).
  static bool isManaged(String? path) =>
      path != null && path.isNotEmpty && p.basename(p.dirname(path)) == _folder;

  /// Compresses [sourcePath] into the store. Returns the stored path, or null
  /// if the source file does not exist / cannot be read.
  static Future<String?> saveFromFile(String scanId, String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    try {
      final src = File(sourcePath);
      if (!await src.exists()) return null;
      return await _write(scanId, await src.readAsBytes());
    } catch (e) {
      debugPrint('⚠️ ScanImageStore.saveFromFile failed: $e');
      return null;
    }
  }

  /// Stores an image that arrived as base64 (e.g. restored from the cloud).
  static Future<String?> saveFromBase64(String scanId, String? b64) async {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return await _write(scanId, base64Decode(b64));
    } catch (e) {
      debugPrint('⚠️ ScanImageStore.saveFromBase64 failed: $e');
      return null;
    }
  }

  static Future<String> _write(String scanId, Uint8List bytes) async {
    final jpg = await compute(_compress, bytes);
    final file = File(p.join((await _dir()).path, '${_safeName(scanId)}.jpg'));
    await file.writeAsBytes(jpg, flush: true);
    return file.path;
  }

  /// Base64 of a stored file for the cloud backup copy (null if unreadable).
  static Future<String?> readBase64(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      return base64Encode(await f.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String? path) async {
    if (!isManaged(path)) return;
    try {
      final f = File(path!);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('⚠️ ScanImageStore.delete failed: $e');
    }
  }

  static String _safeName(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
}

/// Runs in a background isolate: downsizes and re-encodes as JPEG. Falls back
/// to the original bytes if the image cannot be decoded.
Uint8List _compress(Uint8List bytes) {
  try {
    var image = img.decodeImage(bytes);
    if (image == null) return bytes;
    image = img.bakeOrientation(image);
    if (image.width > ScanImageStore._maxSide || image.height > ScanImageStore._maxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: ScanImageStore._maxSide)
          : img.copyResize(image, height: ScanImageStore._maxSide);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: ScanImageStore._jpegQuality));
  } catch (_) {
    return bytes;
  }
}
