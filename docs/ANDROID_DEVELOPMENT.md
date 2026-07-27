# Android Studio & Physical Device Development Guide

## 1. Opening Project in Android Studio
1. Launch Android Studio.
2. Select **Open** and choose `c:\Users\user\shpathon`.
3. Wait for Gradle sync to complete.

## 2. Connecting Physical Android Device via USB
1. On your Android phone, open **Settings -> About Phone -> Tap Build Number 7 times** to enable Developer Options.
2. Open **Settings -> Developer Options -> Enable USB Debugging**.
3. Plug phone into PC via USB cable. Select "Always allow from this computer" when prompted.
4. Verify device detection via `adb devices`:
   ```bash
   adb devices
   ```

## 3. Running & Debugging App
Select your connected Android phone in Android Studio / VS Code and run:
```bash
flutter run
```
