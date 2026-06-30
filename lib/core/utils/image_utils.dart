import 'dart:io';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class ImageUtils {
  /// Validates if the selected file has a supported format (.jpg, .jpeg, .png).
  static bool validateExtension(String filePath) {
    final path = filePath.toLowerCase();
    return path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png');
  }

  /// Checks if the file size is under the maximum threshold (10 MB).
  static Future<bool> validateSize(File file) async {
    try {
      final int length = await file.length();
      // 10MB in bytes = 10 * 1024 * 1024
      const int maxSizeBytes = 10485760;
      LoggingService.info("File size check: ${length / (1024 * 1024)} MB", tag: "ImageUtils");
      return length <= maxSizeBytes;
    } catch (e) {
      LoggingService.error("Failed to check file size", tag: "ImageUtils", error: e);
      return false;
    }
  }

  /// Verifies image integrity by reading basic bytes to check if it's readable.
  static Future<bool> validateIntegrity(File file) async {
    try {
      final List<int> headerBytes = await file.openRead(0, 10).first;
      return headerBytes.isNotEmpty;
    } catch (e) {
      LoggingService.error("Image file corrupted or unreadable", tag: "ImageUtils", error: e);
      return false;
    }
  }
}
