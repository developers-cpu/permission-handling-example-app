# Migration from install_plugin to flutter_app_installer

## Issue
The `install_plugin` package (v2.1.0) was causing build failures with newer Android Gradle Plugin versions due to missing namespace configuration:
```
Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
Namespace not specified.
```

## Solution
Migrated to `flutter_app_installer` (v1.0.1), which is better maintained and compatible with modern AGP versions.

## Changes Made

### 1. Updated pubspec.yaml
```yaml
# Before
install_plugin: ^2.1.0

# After
flutter_app_installer: ^1.0.1
```

### 2. Updated imports
```dart
// Before
import 'package:install_plugin/install_plugin.dart';

// After
import 'package:flutter_app_installer/flutter_app_installer.dart';
```

### 3. Updated API calls
```dart
// Before
await InstallPlugin.install(filePath);

// After
final installer = FlutterAppInstaller();
await installer.installApk(filePath: filePath);
```

## Files Modified
- `pubspec.yaml` - Updated dependency
- `lib/main.dart` - Updated import and API usage
- `lib/services/apk_installer_service.dart` - Updated import and API usage

## Configuration
The AndroidManifest.xml already had the required FileProvider configuration, so no additional changes were needed.

## Build Status
✅ Build successful with `./gradlew assembleDebug`
✅ No diagnostic errors in Dart files
