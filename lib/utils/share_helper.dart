import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<ShareResult?> shareImage({
    required String filePath,
    Rect? sharePosition,
    Rect fallbackSharePosition = const Rect.fromLTWH(0, 0, 1, 1),
  }) async {
    try {
      return await Share.shareXFiles(
        [XFile(filePath)],
        sharePositionOrigin: sharePosition,
      );
    } on PlatformException catch (e) {
      if (e.message?.contains('sharePositionOrigin') ?? false) {
        return Share.shareXFiles(
          [XFile(filePath)],
          sharePositionOrigin: fallbackSharePosition,
        );
      } else {
        rethrow;
      }
    }
  }

  static Future<ShareResult?> shareFile({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    try {
      return await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: text,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<ShareResult?> sharePdf({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    return shareFile(
      filePath: filePath,
      subject: subject ?? 'PDF Document',
      text: text,
    );
  }
}









