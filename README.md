# SeeFood 🍕

A Flutter app that uses your device camera and on-device machine learning to detect food items in real time.

## Features

- **Live camera preview** – full-screen viewfinder using the `camera` package.
- **Food detection** – powered by [Google ML Kit Image Labeling](https://developers.google.com/ml-kit/vision/image-labeling), which runs entirely on-device (no server required).
- **Confidence scores** – each detected label is shown with a colour-coded confidence badge (green ≥ 80 %, yellow ≥ 60 %, orange < 60 %).
- **"No food" feedback** – the app tells you when nothing food-related was found in the frame.

## How it works

1. The app opens the rear camera and shows a live preview.
2. Tap the **capture button** (white circle at the bottom) to take a snapshot.
3. The image is processed by ML Kit's image labeler, which returns a list of labels.
4. Labels are filtered to food-related terms and displayed as an overlay.

## Requirements

| Platform | Minimum version |
|----------|----------------|
| Android  | API 21 (Android 5.0) |
| iOS      | 15.5 |
| Flutter  | 3.10+ |
| Dart     | 3.0+ |

## Getting started

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

> **Note:** A physical device with a real camera is recommended for the best experience. Emulators may not support camera access.

## Project structure

```
lib/
  main.dart                 – App entry point; initialises cameras
  screens/
    camera_screen.dart      – Camera UI, capture button, detection overlay
  services/
    food_detector.dart      – Wraps ML Kit image labeling; filters food labels
  models/
    detection_result.dart   – Plain data class for a label + confidence pair
android/
  app/src/main/
    AndroidManifest.xml     – CAMERA permission declaration
ios/
  Runner/
    Info.plist              – NSCameraUsageDescription
```

## Packages used

| Package | Purpose |
|---------|---------|
| [`camera`](https://pub.dev/packages/camera) | Live camera preview and image capture |
| [`google_mlkit_image_labeling`](https://pub.dev/packages/google_mlkit_image_labeling) | On-device food / object classification |
