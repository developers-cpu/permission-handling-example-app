# Setup Guide - APK Installer App

## Quick Start

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Configure Your API (Optional)
Edit `lib/config/app_config.dart` to set your API endpoint:

```dart
static const String apiBaseUrl = 'https://your-api-server.com';
static const String apkDownloadEndpoint = '/api/latest-apk';
```

### Step 3: Build the App
```bash
# For debug build
flutter build apk --debug

# For release build
flutter build apk --release
```

### Step 4: Install on Device
```bash
# Via Flutter
flutter install

# Or manually install the APK from:
# build/app/outputs/flutter-apk/app-release.apk
```

## Detailed Configuration

### 1. Change App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="Your App Name"
```

### 2. Change Package Name
Edit `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.yourcompany.yourapp"
```

Also update in `android/app/src/main/AndroidManifest.xml` if needed.

### 3. Change App Icon
Replace the launcher icons in:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

### 4. Sign Your APK (For Production)

#### Create a Keystore
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### Configure Signing
Create `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

#### Update build.gradle.kts
Add before `android {` block:
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Add inside `android {` block:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

## Android Version Support

| Android Version | API Level | Supported |
|----------------|-----------|-----------|
| Android 10 (Q) | 29 | ✅ |
| Android 11 (R) | 30 | ✅ |
| Android 12 (S) | 31-32 | ✅ |
| Android 13 (T) | 33 | ✅ |
| Android 14 (U) | 34 | ✅ |
| Android 15 (V) | 35 | ✅ |
| Android 16+ | 35+ | ✅ |

## Permissions Explained

### Required for All Versions
- **INTERNET**: Download APK files from your server
- **ACCESS_NETWORK_STATE**: Check if device is connected to internet
- **REQUEST_INSTALL_PACKAGES**: Install downloaded APK files

### Android 10 and Below (API ≤ 29)
- **WRITE_EXTERNAL_STORAGE**: Save APK to Downloads folder
- **READ_EXTERNAL_STORAGE**: Read APK file for installation

### Android 11+ (API ≥ 30)
- **MANAGE_EXTERNAL_STORAGE**: Full storage access (requires manual approval in Settings)

### Android 13+ (API ≥ 33)
- **POST_NOTIFICATIONS**: Show download progress notifications
- **READ_MEDIA_IMAGES/VIDEO/AUDIO**: Access media files

### Android 14+ (API ≥ 34)
- **READ_MEDIA_VISUAL_USER_SELECTED**: Access user-selected media

## Testing

### Test on Different Android Versions
1. **Android 10**: Test storage permissions
2. **Android 11**: Test MANAGE_EXTERNAL_STORAGE
3. **Android 13**: Test notification permissions
4. **Android 14+**: Test latest permission model

### Test Scenarios
1. ✅ First launch - all permissions requested
2. ✅ Download APK from URL
3. ✅ Install downloaded APK
4. ✅ Handle permission denials
5. ✅ Handle network errors
6. ✅ Handle invalid URLs
7. ✅ Handle corrupted APK files

## Common Issues

### Issue 1: "Permission Denied" Error
**Solution**: 
- Go to Settings > Apps > Your App > Permissions
- Enable all permissions
- For Android 11+: Settings > Apps > Special app access > All files access > Enable for your app

### Issue 2: "Installation Blocked"
**Solution**:
- Go to Settings > Apps > Special app access > Install unknown apps
- Find your app and enable "Allow from this source"

### Issue 3: Download Fails
**Solution**:
- Check internet connection
- Verify URL is correct
- Ensure server allows direct downloads
- Check if URL requires authentication

### Issue 4: APK Not Found After Download
**Solution**:
- Check storage permissions are granted
- Verify download directory exists
- Check available storage space

## API Integration Examples

### Example 1: Simple URL
```dart
final url = 'https://example.com/app.apk';
await apkInstallerService.downloadAndInstall(
  url: url,
  onProgress: (progress) => print('Progress: ${progress * 100}%'),
  onStatusChange: (status) => print('Status: $status'),
);
```

### Example 2: Fetch URL from API
```dart
Future<void> downloadLatestApp() async {
  // Fetch APK URL from your API
  final response = await dio.get('https://your-api.com/latest-version');
  final apkUrl = response.data['download_url'];
  
  // Download and install
  await apkInstallerService.downloadAndInstall(
    url: apkUrl,
    onProgress: (progress) {
      setState(() => _progress = progress);
    },
    onStatusChange: (status) {
      setState(() => _status = status);
    },
  );
}
```

### Example 3: With Authentication
```dart
Future<void> downloadWithAuth() async {
  final dio = Dio();
  dio.options.headers['Authorization'] = 'Bearer YOUR_TOKEN';
  
  final response = await dio.get('https://your-api.com/secure/app.apk');
  // Handle response...
}
```

### Example 4: Version Check
```dart
Future<bool> checkForUpdate() async {
  final response = await dio.get('https://your-api.com/version');
  final latestVersion = response.data['version'];
  final currentVersion = AppConfig.appVersion;
  
  return latestVersion != currentVersion;
}
```

## Production Checklist

- [ ] Change app name
- [ ] Change package name
- [ ] Update app icon
- [ ] Configure API endpoint
- [ ] Create and configure keystore
- [ ] Test on multiple Android versions
- [ ] Test all permission scenarios
- [ ] Test download and install flow
- [ ] Build release APK
- [ ] Test release APK on real devices
- [ ] Document installation process for users

## Security Considerations

⚠️ **Important Security Notes**:

1. **Only use with trusted servers**: This app can install any APK from your server
2. **HTTPS only**: Always use HTTPS URLs for downloads
3. **Verify APK integrity**: Consider adding checksum verification
4. **User consent**: Ensure users understand what they're installing
5. **Not for Play Store**: This app cannot be published on Google Play Store due to policy restrictions

## Support

For issues or questions:
1. Check the troubleshooting section in README.md
2. Review Android documentation for permissions
3. Test on different Android versions
4. Check logcat for detailed error messages

## Additional Resources

- [Android Permissions Guide](https://developer.android.com/guide/topics/permissions/overview)
- [Install Unknown Apps](https://developer.android.com/reference/android/Manifest.permission#REQUEST_INSTALL_PACKAGES)
- [Scoped Storage](https://developer.android.com/about/versions/11/privacy/storage)
- [Flutter Documentation](https://flutter.dev/docs)
