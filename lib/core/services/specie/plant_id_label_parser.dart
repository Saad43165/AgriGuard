class PlantIdLabelParser {
  static const Map<String, String> _speciesMap = {
    'solanum_lycopersicum': 'Tomato',
    'vitis_vinifera': 'Grape',
    'zea_mays': 'Corn',
    'juglans_regia': 'Walnut',
    'ficus_carica': 'Fig',
    'phaseolus_vulgaris': 'Bean',
  };

  String parseScientificName(String label) {
    return _speciesMap[label] ?? _extractFromLabel(label);
  }

  String _extractFromLabel(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  List<String> getSupportedSpecies() => _speciesMap.values.toList();
}