# Sajilo Restro Sewa - Frontend

This is the Flutter frontend application for the **Sajilo Restro Sewa** restaurant management system.

## Prerequisites

- Flutter SDK (v3.12.1 or later)
- Android Studio or appropriate build tools for your target platform (Android / Linux)

## Setup & Installation

Before running the application, you need to fetch all the required Flutter dependencies.

Run the following command in your terminal at the root of the project:

```bash
flutter pub get
```

## Running the Application

This application uses environment variables defined via `--dart-define` to dynamically set the restaurant's branding. **You must include these parameters when running or building the app.**

### Linux

To run the app as a desktop application on Linux:

```bash
flutter run -d linux --dart-define=RESTRO_NAME="Pathway Restro" --dart-define=RESTRO_LOCATION="Patan, Lalitpur"
```

### Android

To run the app on an Android emulator or a connected Android device:

```bash
flutter run -d android --dart-define=RESTRO_NAME="Pathway Restro" --dart-define=RESTRO_LOCATION="Patan, Lalitpur"
```

### Note on Build Profiles
For release builds (APK, AppBundle, or Linux Binaries), make sure to append the identical `--dart-define` arguments to your `flutter build` commands.

```bash
flutter build apk --dart-define=RESTRO_NAME="Pathway Restro" --dart-define=RESTRO_LOCATION="Patan, Lalitpur"
```
