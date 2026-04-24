# 🌿 AgriGuard: Advanced Plant Intelligence

AgriGuard is a premium, AI-powered agricultural companion designed to empower farmers and home gardeners with real-time plant disease detection, smart farm management, and expert agricultural advice.

## 🚀 Key Features

### 🔍 Precision AI Diagnosis
* **Real-time Detection**: Identify over 52 classes of plant health conditions across 12+ species using optimized on-device TensorFlow Lite models.
* **Hybrid Intelligence**: Combines Roboflow's cloud-based precision with local TFLite speed for the best possible accuracy.
* **Dual-Layer Analysis**: Integrated Groq AI (Llama 3.3) provides detailed biological causes, treatment plans, and prevention strategies.

### 🚜 Smart Farm Diary
* **Custom Field Management**: Register and track any crop or plant species, including custom varieties not in the base model.
* **Health Monitoring**: Track the scan history and health status of individual fields or garden plots.
* **Localized Insights**: Get crop-specific growing tips, water needs, and soil recommendations entirely in Urdu or English.

### 💬 Expert Agricultural Advisor
* **AgriBot Assistant**: A specialized chatbot powered by Groq AI to answer complex agricultural questions, from pest control to seasonal planning.
* **Deep Localization**: Full support for Urdu (اردو), making advanced agricultural tech accessible to everyone.

### 📚 Comprehensive Disease Library
* **Knowledge Hub**: A detailed encyclopedia of common plant diseases with high-quality visual references.
* **Offline Access**: Essential disease data is available even without an internet connection.

## 🛠 Technical Stack

* **Framework**: Flutter (Dart)
* **AI/ML**: 
  * TensorFlow Lite (On-device Inference)
  * Roboflow API (Cloud-based Precision Scanning)
  * Groq AI - Llama 3.3 (Agricultural Reasoning)
* **Backend**: Firebase (Auth, Firestore, Cloud Storage)
* **Architecture**: Feature-first layered architecture (Clean Architecture principles)
* **State Management**: Provider

## 🏗 Project Architecture

AgriGuard follows a modular, feature-based structure for maximum scalability:

```text
lib/
├── core/               # Shared utilities, services, and global widgets
├── features/
│   ├── auth/           # Login, Signup, and User Profile
│   ├── capture/        # Camera interface and scan logic
│   ├── chatbot/        # AI-powered chat interface
│   ├── disease_library/ # Encyclopedia and plant data
│   ├── farm_diary/     # Field management and crop tracking
│   ├── history/        # Scan history and statistics
│   └── splash/         # Premium entrance experience
└── main.dart           # App entry point and theme configuration
```

## 📦 Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Saad43165/AgriGuard.git
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the root directory:
   ```env
   GROQ_API_KEY=your_groq_key
   ROBOFLOW_API_KEY=your_roboflow_key
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 License

This project is developed as a Final Year Project. All rights reserved.

---
**Developed with ❤️ by the AgriGuard Team**
