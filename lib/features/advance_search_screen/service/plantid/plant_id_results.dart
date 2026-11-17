class PlantIdResults {
  Map<String, dynamic> noPlantDetected() => {
    'success': true,
    'source': 'Plant.id AI',
    'data': {
      'plantName': 'No plant detected',
      'scientificName': 'N/A',
      'diseaseName': 'N/A',
      'severity': 'N/A',
      'confidence': 0,
      'diseaseConfidence': 0,
      'symptoms': ['Image does not contain a recognizable plant'],
      'remediation': ['Please upload a clear photo of a plant'],
      'precautions': ['Ensure the plant is the main subject of the photo'],
      'additionalInfo': '❌ NO PLANT DETECTED\n\n💡 Tips:\n• Capture clear leaf details\n• Ensure good lighting\n• Focus on distinctive features',
    },
    'isRealData': true,
    'hasDiseaseInfo': false,
  };

  Map<String, dynamic> unknownPlant() => {
    'success': true,
    'source': 'Plant.id AI',
    'data': {
      'plantName': 'Unknown Species',
      'scientificName': 'Unidentified',
      'diseaseName': 'Analysis incomplete',
      'severity': 'Unknown',
      'confidence': 0,
      'diseaseConfidence': 0,
      'symptoms': ['Plant species could not be identified'],
      'remediation': ['Try a different photo with better lighting'],
      'precautions': ['Follow general plant care guidelines'],
      'additionalInfo': '⚠️ SPECIES NOT IDENTIFIED\n\nTry:\n• Different lighting\n• Closer view of leaves\n• Multiple angles',
    },
    'isRealData': true,
    'hasDiseaseInfo': false,
  };

  Map<String, dynamic> fallback() => {
    'success': false,
    'source': 'Plant.id AI',
    'error': 'Failed to parse response',
    'message': 'Could not parse Plant.id response. Please try again.',
  };

  Map<String, dynamic> partialSuccess(String plantName) => {
    'success': true,
    'source': 'Plant.id AI',
    'data': {
      'plantName': plantName,
      'scientificName': plantName,
      'diseaseName': 'Analysis complete - details unavailable',
      'severity': 'Unknown',
      'confidence': 0,
      'diseaseConfidence': 0,
      'symptoms': ['Analysis completed but details could not be parsed'],
      'remediation': ['Try with a different image or use Groq analysis'],
      'precautions': ['Follow general plant care guidelines'],
      'additionalInfo': '✅ Plant identified: $plantName\n\n⚠️ Some details could not be parsed.',
    },
    'isRealData': true,
    'hasDiseaseInfo': false,
  };
}