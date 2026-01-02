# APK Installer App

A Flutter application that downloads and installs APK files from your API server. This app supports Android 10 through Android 16 with all necessary permissions.

## Features

- ✅ Download APK files from any URL
- ✅ Install APK files automatically
- ✅ Support for Android 10, 11, 12, 13, 14, 15, and 16
- ✅ All required permissions handled
- ✅ Progress tracking during download
- ✅ Clean and simple UI

## Permissions Included

This app requests the following permissions based on Android version:

### All Android Versions (10-16)
- `INTERNET` - Download APK files
- `ACCESS_NETWORK_STATE` - Check network connectivity
- `REQUEST_INSTALL_PACKAGES` - Install downloaded APKs

### Android 10 and Below (API 29-)
- `WRITE_EXTERNAL_STORAGE` - Save APK files
- `READ_EXTERNAL_STORAGE` - Read APK files

### Android 11+ (API 30+)
- `MANAGE_EXTERNAL_STORAGE` - Full storage access

### Android 13+ (API 33+)
- `POST_NOTIFICATIONS` - Show download notifications
- `READ_MEDIA_IMAGES` - Media access
- `READ_MEDIA_VIDEO` - Media access
- `READ_MEDIA_AUDIO` - Media access

### Android 14+ (API 34+)
- `READ_MEDIA_VISUAL_USER_SELECTED` - Selected media access

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Build the APK

```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Install on Device

```bash
flutter install
```

Or manually install the APK from the build folder.

## Usage

1. **Grant Permissions**: On first launch, the app will request all necessary permissions. Grant them all.

2. **For Android 11+**: You'll need to manually enable "Allow from this source" in Settings for the MANAGE_EXTERNAL_STORAGE permission.

3. **Enter APK URL**: Input the URL of the APK file from your API server.

4. **Download & Install**: Tap the button to download and install the APK.

5. **Follow Prompts**: Android will show installation prompts - follow them to complete installation.

## API Integration

To integrate with your API server, modify the URL input or hardcode your API endpoint in `lib/main.dart`:

```dart
// Example: Fetch APK URL from your API
Future<String> getApkUrlFromApi() async {
  final response = await dio.get('https://your-api.com/latest-apk');
  return response.data['apk_url'];
}
```

## Important Notes

### Security Considerations
- This app allows installation of APKs from unknown sources
- Only use with trusted API servers
- Users must enable "Install from Unknown Sources" for your app

### Android Version Support
- **Minimum SDK**: 29 (Android 10)
- **Target SDK**: 35 (Android 16)
- **Compile SDK**: 35

### File Storage
- **Android 10 and below**: Downloads to `/storage/emulated/0/Download/`
- **Android 11+**: Downloads to app-specific external storage directory

## Troubleshooting

### Permission Denied Errors
1. Go to Settings > Apps > Your App > Permissions
2. Enable all permissions manually
3. For Android 11+, enable "All files access" in Special app access

### Installation Failed
1. Ensure "Install from Unknown Sources" is enabled for your app
2. Check that the downloaded file is a valid APK
3. Verify the APK is not corrupted during download

### Download Fails
1. Check internet connection
2. Verify the URL is correct and accessible
3. Ensure the server allows direct APK downloads

## Project Structure

```
lib/
├── main.dart                          # Main app UI
└── services/
    └── apk_installer_service.dart     # APK download/install logic

android/
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml        # All permissions configured
│   │   └── res/xml/
│   │       └── provider_paths.xml     # File provider configuration
│   └── build.gradle.kts               # SDK versions configured
```

## Dependencies

- `permission_handler: ^11.3.1` - Handle runtime permissions
- `dio: ^5.4.1` - HTTP client for downloading
- `path_provider: ^2.1.2` - Get storage paths
- `install_plugin: ^2.1.0` - Install APK files

## Building for Production

1. **Update Application ID**: Change the package name in `android/app/build.gradle.kts`

```kotlin
applicationId = "com.yourcompany.yourapp"
```

2. **Update App Name**: Modify `android/app/src/main/AndroidManifest.xml`

```xml
android:label="Your App Name"
```

3. **Add App Icon**: Replace icons in `android/app/src/main/res/mipmap-*/`

4. **Sign the APK**: Configure signing in `android/app/build.gradle.kts`

```kotlin
signingConfigs {
    release {
        storeFile = file("your-keystore.jks")
        storePassword = "your-password"
        keyAlias = "your-alias"
        keyPassword = "your-password"
    }
}
```

5. **Build Release APK**:

```bash
flutter build apk --release
```

## License

This project is for internal use as an app installer/updater.

## Support

For issues or questions, contact your development team.

