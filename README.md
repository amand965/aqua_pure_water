# Aqua Pure Water 💧

Aqua Pure Water is a Flutter application designed for managing customers, service records, and due services.

---

## 🚀 Getting Started

To run this project locally, you need to follow these steps:

### 1. Prerequisites
- Flutter SDK installed on your machine.
- Android Studio / VS Code configured for Flutter.

### 2. Firebase Configuration (`google-services.json`) 🔒
For security reasons, the Firebase configuration file (`google-services.json`) is not included in this repository. You must add your own to run the app:

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project (or use an existing one) and add an Android app with the package name of this project.
3. Download the `google-services.json` file.
4. Place the downloaded `google-services.json` file in the following directory:
   ```
   android/app/google-services.json
   ```

### 3. Running the App
Once the Firebase file is in place, run the following commands in the project root:

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📦 APK File
A pre-built release APK is available in the root of the repository:
- [app-release.apk](./app-release.apk) (You can download this directly to test the app on an Android device).
