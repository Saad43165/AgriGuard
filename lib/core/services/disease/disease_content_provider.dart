class DiseaseContentProvider {
  String determineSeverity(String diseaseName, double confidence) {
    final d = diseaseName.toLowerCase();
    if (d == 'healthy') return 'None';

    const high = ['late blight', 'bacterial spot', 'black rot', 'rust', 'blight'];
    const medium = ['early blight', 'powdery mildew', 'leaf spot', 'scorch'];

    for (var h in high) { if (d.contains(h)) return 'High'; }
    for (var m in medium) { if (d.contains(m)) return 'Medium'; }

    if (confidence > 70) return 'High';
    if (confidence > 40) return 'Medium';
    return 'Low';
  }

  String getCause(String diseaseName) {
    final l = diseaseName.toLowerCase();

    if (l.contains('apple scab')) return 'Fungus Venturia inaequalis';
    if (l.contains('cedar apple rust')) return 'Fungus Gymnosporangium juniperi-virginianae';
    if (l.contains('late blight')) return 'Oomycete Phytophthora infestans';
    if (l.contains('early blight')) return 'Fungus Alternaria solani';
    if (l.contains('powdery mildew')) return 'Fungal mildew (Podosphaera or Erysiphe)';
    if (l.contains('bacterial spot')) return 'Bacterium Xanthomonas species';
    if (l.contains('black rot')) return 'Fungus (apple) or Guignardia bidwellii (grape)';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('septoria')) return 'Fungus Septoria lycopersici';
    if (l.contains('spider mites')) return 'Arachnid Tetranychus urticae';
    if (l.contains('yellow leaf curl')) return 'Begomovirus TYLCV';
    if (l.contains('mosaic virus')) return 'Tobamovirus ToMV';
    if (l.contains('leaf mold')) return 'Fungus Passalora fulva';
    if (l.contains('esca')) return 'Complex of fungi';
    if (l.contains('haunglongbing')) return 'Bacterium Candidatus Liberibacter asiaticus';
    if (l.contains('cercospora')) return 'Fungus Cercospora zeae-maydis';
    if (l.contains('northern leaf blight')) return 'Fungus Exserohilum turcicum';
    if (l.contains('target spot')) return 'Fungus Corynespora cassiicola';
    if (l.contains('leaf scorch')) return 'Fungus Diplocarpon earlianum';

    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rot')) return 'Fungal or bacterial decay';
    if (l.contains('scorch')) return 'Environmental stress or fungal infection';
    if (l.contains('curl')) return 'Viral infection';

    return 'Pathogen infection or environmental stress';
  }

  List<String> getSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') return ['No visible symptoms', 'Normal leaf color', 'Vigorous growth'];

    if (l.contains('late blight')) return ['Water-soaked lesions turning brown-black', 'White fuzzy growth underneath', 'Rapid plant collapse'];
    if (l.contains('early blight')) return ['Dark brown lesions with concentric rings', 'Yellow halo around lesions', 'Premature defoliation'];
    if (l.contains('powdery mildew')) return ['White powdery coating on leaves', 'Leaf curling and distortion', 'Stunted growth'];
    if (l.contains('rust')) return ['Orange-brown pustules on leaves', 'Pustules turn black over time'];
    if (l.contains('bacterial spot')) return ['Small water-soaked spots', 'Yellow halos', 'Shot-hole appearance'];
    if (l.contains('apple scab')) return ['Olive-green to brown lesions', 'Velvety spots', 'Premature leaf drop'];
    if (l.contains('cedar apple rust')) return ['Bright yellow-orange spots', 'Tube-like structures underneath'];
    if (l.contains('black rot')) return ['Tan lesions with dark borders', 'Mummified berries on grape'];
    if (l.contains('septoria')) return ['Small circular spots with dark borders', 'Tan/gray centers'];
    if (l.contains('spider mites')) return ['Fine stippling on leaves', 'Bronze/yellow discoloration', 'Fine webbing'];
    if (l.contains('yellow leaf curl')) return ['Upward curling and yellowing', 'Stunted growth', 'Reduced fruit'];
    if (l.contains('mosaic virus')) return ['Mosaic light/dark green pattern', 'Leaf distortion'];
    if (l.contains('leaf mold')) return ['Pale spots on upper surface', 'Olive-green mold underneath'];
    if (l.contains('esca')) return ['Tiger-stripe pattern on leaves', 'Black spots on berries'];
    if (l.contains('haunglongbing')) return ['Asymmetric yellowing', 'Small lopsided fruit', 'Twig dieback'];

    return ['Abnormal leaf discoloration', 'Spots or lesions on leaves', 'Reduced plant vigor'];
  }

  List<String> getRemediation(String diseaseName, String plantName, bool isHealthy) {
    if (isHealthy) {
      return [
      'Continue current care regimen',
      'Maintain proper watering schedule',
      'Ensure adequate sunlight exposure',
      'Regular monitoring for early disease detection',
    ];
    }

    final l = diseaseName.toLowerCase();
    final base = <String>[
      'Remove and destroy infected leaves',
      'Improve air circulation',
      'Avoid overhead watering',
      'Clean and disinfect tools',
    ];

    if (l.contains('haunglongbing')) {
      return [
      'NO CURE — Remove infected trees immediately',
      'Control psyllid with systemic insecticides',
      'Use certified disease-free nursery stock',
    ];
    }

    if (l.contains('yellow leaf curl')) {
      return [
      'NO CURE — Remove infected plants',
      'Control whitefly vectors',
      'Plant resistant varieties',
    ];
    }

    if (l.contains('late blight')) {
      return [
      ...base,
      'Apply metalaxyl or chlorothalonil IMMEDIATELY',
      'Destroy infected plants to prevent spread',
    ];
    }

    if (l.contains('early blight')) {
      return [
      ...base,
      'Apply chlorothalonil or mancozeb fungicides',
      'Mulch to prevent soil splash',
    ];
    }

    if (l.contains('powdery mildew')) {
      return [
      ...base,
      'Apply sulfur or potassium bicarbonate',
      'Increase plant spacing for air flow',
    ];
    }

    if (l.contains('rust')) {
      return [
      ...base,
      'Apply triazole or strobilurin fungicides',
      'Use resistant varieties',
    ];
    }

    return [...base, 'Apply appropriate treatment', 'Consult agricultural expert if severe'];
  }

  List<String> getPrecautions(String diseaseName, String plantName) {
    final base = <String>[
      'Regularly inspect plants',
      'Maintain proper spacing',
      'Water at the base',
      'Use disease-resistant varieties',
      'Clean garden debris',
    ];

    if (diseaseName.toLowerCase() != 'healthy') {
      base.addAll(['Isolate new plants', 'Avoid working when wet', 'Sterilize tools']);
    }

    return base;
  }
}