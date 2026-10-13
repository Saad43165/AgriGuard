import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageHelper {
  static Future<Map<String, dynamic>?> pickAndProcessImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final base64String = await _convertImageToBase64(file);

        if (base64String != null) {
          return {
            'file': file,
            'base64': base64String,
          };
        }
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      Uint8List compressedBytes = bytes;

      if (bytes.length > 500000) {
        compressedBytes = await _compressImage(bytes);
      }

      return base64Encode(compressedBytes);
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final codec = await instantiateImageCodec(
        bytes,
        targetWidth: 300,
        targetHeight: 300,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      return bytes;
    }
  }
}