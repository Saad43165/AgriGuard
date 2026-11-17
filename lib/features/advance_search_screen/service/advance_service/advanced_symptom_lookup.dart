class AdvancedSymptomLookup {
  List<String> getSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') {
      return const ['No visible symptoms', 'Normal leaf color and texture'];
    }
    if (l.contains('rust')) {
      return const ['Orange/yellow lesions', 'Rust-colored pustules', 'Premature leaf drop'];
    }
    if (l.contains('blight')) {
      return const ['Dark lesions on leaves', 'Yellowing around lesions', 'Rapid spread in humidity'];
    }
    if (l.contains('spot')) {
      return const ['Small circular spots', 'Yellow halos', 'Spots may merge over time'];
    }
    return const ['Leaf discoloration', 'Spots or lesions', 'Reduced plant vigor'];
  }

  String getCause(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('mildew')) return 'Fungal mildew infection';
    if (l == 'healthy') return 'No disease detected';
    return 'Environmental factors or pathogen infection';
  }

  String getGroqErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('groq_api_key') || errorStr.contains('401') || errorStr.contains('403')) {
      return 'Invalid Groq API key. Check GROQ_API_KEY.';
    }
    if (errorStr.contains('429')) return 'Groq rate limit reached. Try again later.';
    if (errorStr.contains('timeout')) return 'Groq request timed out. Check internet connection.';
    if (errorStr.contains('quota')) return 'Groq quota exceeded. Check usage limits.';
    return 'Groq analysis failed: $errorStr';
  }

  String getPlantIdErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('402') || errorStr.contains('credits exhausted')) {
      return 'Plant.id credits exhausted. Please use Groq analysis instead.';
    }
    if (errorStr.contains('api_key') || errorStr.contains('401')) return 'Invalid Plant.id API key.';
    if (errorStr.contains('timeout')) return 'Plant.id request timed out.';
    return 'Plant.id analysis failed: $errorStr';
  }
}