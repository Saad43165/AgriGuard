# 🌿 AgriGuard: Advanced Plant Intelligence

AgriGuard is a premium, AI-powered agricultural companion designed to empower farmers and home gardeners with real-time plant disease detection, smart farm management, and expert agricultural advice.

## 🚀 Key Features

### 🔍 Precision AI Diagnosis
* **Real-time Detection**: Identify 35 plant health conditions on-device with an EfficientNet-B3 TensorFlow Lite model, plus a severity model.
* **Hybrid Intelligence**: Combines Plant.id's cloud-based precision with local TFLite speed for the best possible accuracy.
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
  * Plant.id API (Cloud-based Precision Scanning)
  * Groq AI - Llama 3.3 (Agricultural Reasoning)
* **Backend**: Firebase (Auth, Firestore) + local SQLite (sqflite)
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
   Copy `.env.example` to `.env` in the project root and fill in your keys:
   ```env
   GROQ_API_KEY=your_groq_key
   PLANTID_API_KEY=your_plantid_key
   ```
   `.env` is git-ignored — never commit it.

4. **Deploy Firebase security rules** (once per Firebase project):
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 License

This project is developed as a Final Year Project. All rights reserved.

---
**Developed with ❤️ by the AgriGuard Team**
