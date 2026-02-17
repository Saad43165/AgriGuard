class FileNameGenerator {
  static String generate() {
    final timestamp = DateTime.now();
    return 'AgriGuard_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
  }
}