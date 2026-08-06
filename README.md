# MarketPlace 🌱

A comprehensive Flutter-based mobile application that connects farmers and buyers. It leverages modern backend technologies and artificial intelligence to provide a seamless marketplace experience, complete with crop disease detection and voice assistance.

## 🚀 Features

- **Two-Sided Marketplace:** Dedicated interfaces for both **Farmers** (to list crops, manage inventory, and monitor health) and **Buyers** (to browse, search, and purchase produce).
- **AI Crop Disease Detection:** Integrates a custom on-device machine learning model (TensorFlow Lite / MobileNetV3) to help farmers detect tomato and other crop diseases instantly from images.
- **Generative AI Assistant:** Powered by **Google Generative AI (Gemini)** to provide smart insights, farming tips, and conversational support.
- **Voice Capabilities:** Built-in `speech_to_text` integration for accessible, hands-free voice input.
- **Robust Authentication:** Secure user authentication using Firebase Auth, including **Google Sign-In** and **Facebook Auth**.
- **Cloud Infrastructure:** Real-time database operations, user management, and image hosting powered by Firebase (Cloud Firestore, Firebase Storage).

## 🛠️ Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) & Dart
- **Backend as a Service:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage, Analytics, Messaging)
- **Machine Learning:** [TensorFlow Lite](https://www.tensorflow.org/lite) (`tflite_flutter`)
- **AI Integration:** Google Generative AI (`google_generative_ai`)
- **Environment Management:** `flutter_dotenv` for secure API key management

## 📦 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.9.2 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- A Firebase project with Auth, Firestore, and Storage enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jaguarpawjr/MarketPlace.git
   cd MarketPlace
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup (.env):**
   Create a `.env` file in the root of the project to store your secure API keys. This is required for Firebase and Gemini AI configurations.
   ```env
   FIREBASE_WEB_API_KEY=your_api_key
   FIREBASE_WEB_APP_ID=your_app_id
   FIREBASE_ANDROID_API_KEY=your_api_key
   FIREBASE_ANDROID_APP_ID=your_app_id
   GEMINI_API_KEY=your_gemini_api_key
   ```
   *(Note: Never commit your `.env` file to version control. It is already added to `.gitignore`)*

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📁 Project Structure

- `lib/screens_farmer/` - UI and logic for the Farmer's dashboard and features.
- `lib/screens_buyer/` - UI and logic for the Buyer's browsing and purchasing experience.
- `lib/Auth/` - Authentication screens and logic.
- `lib/services/` - Core services for Firebase interactions and AI model execution.
- `lib/models/` - Data models for Firestore serialization.
- `MobileNetV3_Tomato_Training_Folder/` - Model training resources and Jupyter notebooks for the TensorFlow Lite disease detection model.

## 🤝 Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License
This project is licensed under the MIT License.
