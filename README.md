# Antigravity Enterprise Restaurant ERP & POS (Flutter Mobile & Tablet App)

A modern, cross-platform mobile and tablet solution built with Flutter, designed to seamlessly operate across touchscreen devices in a restaurant ecosystem. Configured to interface with the enterprise backend running on LAN IP `http://192.168.32.249:8107/api`.

## Key Architectural Highlights & Features
- **Ultra-Modern Custom UI System**: Rich HSL curated color palette (Deep Emerald, Vibrant Crimson, Slate Gray, Warm Amber), glassmorphic layout cards, and custom Google Fonts typography (`Outfit` & `Inter`) without heavy third-party template plugins.
- **Role-Based Fast Switch PIN Security**: Instantaneous terminal transition between **Lead Waiters**, **Executive Chef KDS Stations**, **Main Cashier Billing**, and **Storekeeper Inventory Scanning** using secure 4-digit PIN authentication.
- **Resilient Offline Cache Strategy**: Powered by Dio interceptors and SQLite local queuing to ensure that table orders punched during transient dining room Wi-Fi drops automatically re-sync when network connectivity returns.
- **Automated KDS & COGS Integration**: Kitchen staff tapping "Mark Ready" sends an event to automatically subtract accurate raw ingredient quantities mapped to each dish in the central stores warehouse.

## Compilation Instructions (APK & iOS IPA)

### 1. Android APK & App Bundle
To generate an optimized Android installation package (APK) for restaurant waitstaff handheld tablets and kitchen terminals:
```bash
# Fetch dependencies
flutter pub get

# Compile Release APK
flutter build apk --release

# Compiled APK will be output at:
# build/app/outputs/flutter-apk/app-release.apk
```

### 2. iOS IPA (For Apple iPad KDS & Handhelds)
To compile an iOS IPA archive for deployment to dining room iPads:
```bash
# Install iOS pods and build IPA
flutter pub get
cd ios && pod install && cd ..

# Compile Archive & IPA
flutter build ipa --release
```

## Backend Host Configuration
The networking endpoint is defaulted to `http://192.168.32.249:8107/api` (as configured in `lib/core/network/api_client.dart`). Ensure your local IT admin terminal authorization includes your device's LAN IP address on the firewall portal!
