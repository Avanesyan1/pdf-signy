import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:image/image.dart' as img;
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

/// Utility class for picking PDF documents
class DocumentPickerUtils {
  /// Result of picking a PDF document
  static Future<PdfDocumentResult?> pickPdfDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final fileName = result.files.single.name;

        return PdfDocumentResult(bytes: Uint8List.fromList(bytes), fileName: fileName);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking PDF document: $e');
      }
    }
    return null;
  }

  /// Scans document using flutter_doc_scanner and converts to PDF
  static Future<PdfDocumentResult?> scanDocument() async {
    try {
      // Get scanned document as images (flutter_doc_scanner handles permissions)
      // Note: This may show camera errors on simulator - this is normal
      final imagePaths = await FlutterDocScanner().getScannedDocumentAsImages(page: 1);

      if (imagePaths.isEmpty || imagePaths[0] == null || imagePaths[0]!.isEmpty) {
        if (kDebugMode) {
          print('No images returned from scanner');
        }
        return null;
      }

      // Convert scanned image to PDF
      final pdfBytes = await _convertImageToPdf(imagePaths[0]!);
      if (pdfBytes == null) {
        if (kDebugMode) {
          print('Failed to convert image to PDF');
        }
        return null;
      }

      // Generate filename with timestamp
      final fileName = 'Scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';

      return PdfDocumentResult(bytes: pdfBytes, fileName: fileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error in scanDocument: $e');
      }
    }
    return null;
  }

  /// Picks image from gallery and converts to PDF
  static Future<PdfDocumentResult?> pickImageFromGallery() async {
    try {
      // Pick image from gallery (imageQuality removed to avoid warnings)
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        return null;
      }

      // Convert image to PDF
      final pdfBytes = await _convertImageToPdf(image.path);
      if (pdfBytes == null) {
        return null;
      }

      // Generate filename with timestamp
      final fileName = 'Image_${DateTime.now().millisecondsSinceEpoch}.pdf';

      return PdfDocumentResult(bytes: pdfBytes, fileName: fileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error in pickImageFromGallery: $e');
      }
    }
    return null;
  }

  /// Converts image file path to PDF bytes
  static Future<Uint8List?> _convertImageToPdf(String imagePath) async {
    try {
      // Read image file
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return null;
      }

      // Create PDF document
      final pdf = pdf_widgets.Document();

      // Convert image to PDF image format
      final pdfImage = pdf_widgets.MemoryImage(imageBytes);

      // Calculate page format based on image dimensions
      // Use A4 format but scale image to fit
      final pageFormat = pdf_lib.PdfPageFormat.a4;
      final imageAspectRatio = image.width / image.height;
      final pageAspectRatio = pageFormat.width / pageFormat.height;

      double imageWidth;
      double imageHeight;

      if (imageAspectRatio > pageAspectRatio) {
        // Image is wider - fit to width
        imageWidth = pageFormat.width - 40; // 20px margin on each side
        imageHeight = imageWidth / imageAspectRatio;
      } else {
        // Image is taller - fit to height
        imageHeight = pageFormat.height - 40; // 20px margin on each side
        imageWidth = imageHeight * imageAspectRatio;
      }

      // Add image to PDF page
      pdf.addPage(
        pdf_widgets.Page(
          pageFormat: pageFormat,
          build: (pdf_widgets.Context context) {
            return pdf_widgets.Center(
              child: pdf_widgets.Image(
                pdfImage,
                width: imageWidth,
                height: imageHeight,
                fit: pdf_widgets.BoxFit.contain,
              ),
            );
          },
        ),
      );

      // Save PDF as bytes
      final pdfBytes = await pdf.save();

      return Uint8List.fromList(pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting image to PDF: $e');
      }
    }
    return null;
  }
}

/// Result of picking a PDF document
class PdfDocumentResult {
  final Uint8List bytes;
  final String fileName;

  PdfDocumentResult({required this.bytes, required this.fileName});
}
