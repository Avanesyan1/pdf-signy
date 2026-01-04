import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// Utility class for picking images
class ImagePickerUtils {
  /// Picks image from gallery
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) {
        return null;
      }

      final file = File(image.path);
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Picks image from camera
  static Future<Uint8List?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();

      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        return null;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null) {
        return null;
      }

      final file = File(image.path);
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Picks image from files
  static Future<Uint8List?> pickImageFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsBytes();
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}





