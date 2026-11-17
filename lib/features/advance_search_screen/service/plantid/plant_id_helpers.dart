class PlantIdHelpers {
  String buildAdditionalInfo({
    required String plantName,
    required List<String> commonNames,
    required int confidence,
    required bool hasDiseaseInfo,
    required String diseaseName,
    required double diseaseProbability,
    required String description,
  }) {
    final buffer = StringBuffer();
    buffer.write('🌿 PLANT.ID V3 ANALYSIS REPORT\n');
    buffer.write('═' * 40);
    buffer.write('\n\n🪴 PLANT IDENTIFICATION\n');
    buffer.write('─' * 40);
    buffer.write('\n');

    if (commonNames.isNotEmpty) buffer.write('Common Name: ${commonNames.first}\n');
    buffer.write('Scientific Name: $plantName\n');
    buffer.write('Confidence: $confidence%\n');

    if (description.isNotEmpty && description != 'Plant identified successfully') {
      final short = description.length > 150 ? '${description.substring(0, 150)}...' : description;
      buffer.write('\nDescription: $short\n');
    }

    buffer.write('\n🏥 HEALTH ASSESSMENT\n');
    buffer.write('─' * 40);
    buffer.write('\n');

    if (hasDiseaseInfo) {
      buffer.write('Status: ⚠️ DISEASE DETECTED\n');
      buffer.write('Condition: $diseaseName\n');
      buffer.write('Disease Confidence: ${(diseaseProbability * 100).toStringAsFixed(1)}%\n');
      buffer.write('\n💡 IMMEDIATE ACTIONS:\n');
      buffer.write('• Review symptoms carefully\n');
      buffer.write('• Begin treatment immediately\n');
      buffer.write('• Monitor plant response daily\n');
      buffer.write('• Isolate from healthy plants\n');
    } else {
      buffer.write('Status: ✅ HEALTHY\n');
      buffer.write('\n💡 MAINTENANCE:\n');
      buffer.write('• Continue current care\n');
      buffer.write('• Regular monitoring\n');
      buffer.write('• Maintain optimal conditions\n');
    }

    buffer.write('\n⚙️ DETAILS\n');
    buffer.write('─' * 40);
    buffer.write('\nAPI: Plant.id v3\n');
    buffer.write('Date: ${DateTime.now().toString().split('.')[0]}\n');

    return buffer.toString();
  }
}