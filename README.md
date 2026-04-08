**AgriGuard - Flutter Application (In Development)**
AgriGuard is a Flutter-based mobile application being developed as a Final Year Project (FYP) to support farmers and agricultural professionals. The app aims to simplify crop management by providing tools for scanning prescriptions, monitoring plant health, and managing farm operations. This project is actively under development, with new features and improvements being added regularly.
Current Features
**Prescription Scanning:** Capture or upload images of agricultural prescriptions (e.g., for pesticides or fertilizers) and extract medicine details using image processing and API integration.
**Image Processing:** Compress and store images efficiently for seamless scanning and processing.
**User-Friendly Navigation:** Includes a bottom navigation bar to switch between Home, Scan, and Profile screens.
**Cross-Platform Support:** Built with Flutter to run on both Android and iOS devices.
**Error Handling:** Robust handling for image picking, compression, and API errors with user-friendly feedback via snackbars.
**Planned Features**
**Plant Health Monitoring:** Analyze plant images to detect diseases or nutrient deficiencies.
**User Profiles:** Store and display user-specific data, such as farm details and scan history.
**Localization:** Support multiple languages for broader accessibility.
**Enhanced UI/UX:** Add animations, glassmorphism effects, and consistent theming across all screens.
**Offline Support:** Enable scanning and data storage without an internet connection.

## On-device (TFLite) plant analysis models
The on-device scanning flow depends on three TensorFlow Lite model files that must be present in `assets/models/` and listed in `pubspec.yaml`.

### Required files
- `assets/models/plant_species_final_quantized.tflite`
- `assets/models/plant_disease_dynamic_quant.tflite`
- `assets/models/severity_dynamic_quant.tflite`

### Label/metadata files (committed)
- `assets/models/labels.txt`
- `assets/models/disease_labels.txt`
- `assets/models/severity_labels.txt`
- `assets/models/model_info.json`

### Notes
- If the app shows “model loading” failures on first launch, verify the `.tflite` files exist at the paths above and run `flutter pub get` so assets are bundled correctly.
- If you keep models out of git (size/licensing), ensure your team has a consistent way to obtain them and place them into `assets/models/` before running the app.

## Advanced Scan (Groq + Plant.id) setup
This project uses environment variables for API keys via a local `.env` file (not committed).

Create a `.env` file in the project root:

```env
# Hugging Face (free-tier vision detection)
HF_API_TOKEN=your_token_here
# Pick a plant-disease image classification model on HF
HF_MODEL=dima806/plant-disease-classification

# Groq (Cloud AI text assistant)
GROQ_API_KEY=your_key_here
# optional
GROQ_MODEL=llama-3.1-70b-versatile

# Plant.id (optional alternative)
PLANTID_API_KEY=your_key_here
```
