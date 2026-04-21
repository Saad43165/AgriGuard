// lib/features/support/models/faq_category.dart
import 'package:flutter/material.dart';

enum FaqCategory {
  general,
  scanning,
  database,
  account,
  technical,
  sharing;

  IconData get icon {
    switch (this) {
      case FaqCategory.general:
        return Icons.info_rounded;
      case FaqCategory.scanning:
        return Icons.camera_alt_rounded;
      case FaqCategory.database:
        return Icons.storage_rounded;
      case FaqCategory.account:
        return Icons.person_rounded;
      case FaqCategory.technical:
        return Icons.settings_rounded;
      case FaqCategory.sharing:
        return Icons.share_rounded;
    }
  }

  String getLabel(bool isUrdu) {
    if (isUrdu) {
      switch (this) {
        case FaqCategory.general:
          return 'عام';
        case FaqCategory.scanning:
          return 'اسکیننگ';
        case FaqCategory.database:
          return 'ڈیٹا بیس';
        case FaqCategory.account:
          return 'اکاؤنٹ';
        case FaqCategory.technical:
          return 'تکنیکی';
        case FaqCategory.sharing:
          return 'شیئرنگ';
      }
    } else {
      switch (this) {
        case FaqCategory.general:
          return 'General';
        case FaqCategory.scanning:
          return 'Scanning';
        case FaqCategory.database:
          return 'Database';
        case FaqCategory.account:
          return 'Account';
        case FaqCategory.technical:
          return 'Technical';
        case FaqCategory.sharing:
          return 'Sharing';
      }
    }
  }

  String get label => getLabel(false); // Default English for backward compatibility
}