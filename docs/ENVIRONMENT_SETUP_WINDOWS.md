# Environment Setup Guide (Fresh Windows PC)

Follow these steps to set up a clean Windows machine for Flutter Android development:

## 1. Prerequisites Installation
1. **Git for Windows**: Download from [git-scm.com](https://git-scm.com/)
2. **Flutter Stable SDK**:
   - Download Flutter 3.44+ SDK
   - Extract to `C:\src\flutter`
   - Add `C:\src\flutter\bin` to Windows System PATH environment variables
3. **Android Studio**:
   - Download Android Studio Ladybug or latest stable from [developer.android.com](https://developer.android.com/studio)
   - Install standard SDK components (Android SDK Platform, SDK Build-Tools, NDK)
   - Run `flutter doctor --android-licenses` and accept all licenses
4. **Node.js LTS & Supabase CLI**:
   - Install Node.js v24+
   - Install Supabase CLI via `npm i -g supabase`

## 2. Verification Command
Run in PowerShell:
```powershell
flutter doctor -v
```
Ensure Android toolchain and Connected device are green.
