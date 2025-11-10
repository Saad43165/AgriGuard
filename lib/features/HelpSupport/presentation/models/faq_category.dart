import 'package:flutter/material.dart';

enum FaqCategory {
  general('General', Icons.help_outline_rounded),
  scanning('Plant Scanning', Icons.camera_alt_rounded),
  database('Database', Icons.storage_rounded),
  account('Account', Icons.person_outline_rounded),
  technical('Technical', Icons.settings_rounded),
  sharing('Sharing', Icons.share_rounded);

  const FaqCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}