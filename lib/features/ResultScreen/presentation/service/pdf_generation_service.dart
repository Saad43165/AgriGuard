import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../home/screens/PdfDialogs/SuccessPdfDialog/pdf_success_dialog.dart';
import '../../../home/screens/PdfDialogs/services/pdf_action_services.dart';

class PdfGenerationService {
  final PdfActionsService _pdfService = PdfActionsService();

  Future<void> generateAndShowPdf({
    required BuildContext context,
    required Map<String, dynamic> scanData,
    required Function(String) onError,
    required Function(File) onSuccess,
  }) async {
    try {
      await _pdfService.generateAndShowPdf(
        context: context,
        scan: scanData,
        onError: onError,
        onSuccess: onSuccess,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PDF generation error: $e');
      debugPrint('Stack trace: $stackTrace');
      onError('Unexpected error: $e');
    }
  }

  Future<void> showPdfSuccessDialog(
      BuildContext context,
      File pdfFile,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => PdfSuccessDialog(pdfFile: pdfFile),
    );
  }
}