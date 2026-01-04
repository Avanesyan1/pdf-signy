import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PrintHelper {
  static Future<void> printPdf({required Uint8List pdfBytes, String? name}) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: name ?? 'Document',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> printPdfFromPath({required String filePath, String? name}) async {
    try {
      final file = File(filePath);
      final pdfBytes = await file.readAsBytes();
      await printPdf(pdfBytes: pdfBytes, name: name);
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> canPrint() async {
    return await Printing.info().then((info) => info.canPrint);
  }
}
