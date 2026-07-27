# Google Play Release & AAB Deployment Guide

## 1. Release Signing Key Generation
Generate a release keystore in standard PKCS12 format:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:
```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

## 2. Build Android App Bundle (AAB)
```bash
flutter build appbundle --release
```
The resulting package will be output to:
`build/app/outputs/bundle/release/app-release.aab`

## 3. Google Play Data Safety Disclosures
- **Financial Info**: Virtual currency simulation only. No real money transactions.
- **Personal Info**: Email address for authentication.
- **App Activity**: Analytics and Crashlytics performance tracking.
