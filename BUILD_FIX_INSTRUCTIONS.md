# Build Fix Instructions

## The Problem
The `install_plugin` package is incompatible with newer Android Gradle Plugin versions. I've replaced it with `open_filex` which works perfectly with modern Android.

## Quick Fix (Run these commands in order)

### Step 1: Delete pubspec.lock
```bash
rm pubspec.lock
```

### Step 2: Clean Flutter
```bash
flutter clean
```

### Step 3: Get Dependencies
```bash
flutter pub get
```

### Step 4: Build
```bash
flutter build apk --debug
```

## Or Use the Fix Script

I've created a script that does all the above steps:

```bash
./fix_build.sh
```

Then build:
```bash
flutter build apk --debug
```

## What Changed

### Before (Broken)
- Used `install_plugin: ^2.1.0` - incompatible with AGP 8+

### After (Fixed)
- Using `open_filex: ^4.5.0` - fully compatible with modern Android
- Same functionality - opens APK files to trigger installation
- Better maintained and more reliable

## Verify the Fix

After running the commands, verify that `install_plugin` is gone:

```bash
flutter pub deps | grep install_plugin
```

This should return nothing. If it still shows `install_plugin`, you may need to:

1. Delete the entire `build/` directory:
   ```bash
   rm -rf build/
   ```

2. Delete `.dart_tool/` directory:
   ```bash
   rm -rf .dart_tool/
   ```

3. Run again:
   ```bash
   flutter pub get
   flutter build apk --debug
   ```

## If Still Having Issues

### Option 1: Nuclear Clean
```bash
rm -rf build/
rm -rf .dart_tool/
rm pubspec.lock
flutter pub cache repair
flutter pub get
flutter build apk --debug
```

### Option 2: Check Flutter Version
Make sure you're using a recent Flutter version:
```bash
flutter --version
```

If it's old, upgrade:
```bash
flutter upgrade
```

### Option 3: Check Android Studio/SDK
Ensure you have:
- Android SDK 35 (Android 16)
- Android SDK Build-Tools 35.0.0
- Android Gradle Plugin 8.0+

## Expected Output

After successful build, you should see:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX.XMB)
```

## Testing the App

Once built successfully:

1. Install on device:
   ```bash
   flutter install
   ```

2. Grant all permissions when prompted

3. Enter an APK URL and test download/install

## Need Help?

If you're still getting errors:
1. Copy the full error message
2. Check if `pubspec.yaml` has `open_filex` (not `install_plugin`)
3. Verify `pubspec.lock` doesn't exist or doesn't reference `install_plugin`
4. Try the nuclear clean option above
