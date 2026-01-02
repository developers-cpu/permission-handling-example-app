/// App Configuration
/// Customize these values for your specific use case
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://your-api-server.com';
  static const String apkDownloadEndpoint = '/api/latest-apk';
  
  // App Information
  static const String appName = 'APK Installer';
  static const String appVersion = '1.0.0';
  
  // Download Configuration
  static const int downloadTimeoutMinutes = 10;
  static const String defaultApkFileName = 'downloaded_app.apk';
  
  // Storage Configuration
  static const String downloadFolderName = 'Download';
  
  // Permission Messages
  static const String storagePermissionMessage = 
      'Storage permission is required to download APK files';
  static const String installPermissionMessage = 
      'Install permission is required to install downloaded apps';
  static const String notificationPermissionMessage = 
      'Notification permission is required to show download progress';
  
  // Error Messages
  static const String downloadErrorMessage = 'Failed to download APK';
  static const String installErrorMessage = 'Failed to install APK';
  static const String permissionDeniedMessage = 'Required permissions not granted';
  
  // Success Messages
  static const String downloadSuccessMessage = 'Download completed successfully';
  static const String installSuccessMessage = 'Installation started';
  
  // UI Configuration
  static const bool showAndroidVersionInfo = true;
  static const bool showPermissionStatus = true;
  static const bool enableCleanupOldApks = true;
  
  // Debug Configuration
  static const bool enableDebugLogs = true;
  
  /// Get full APK download URL
  static String getApkDownloadUrl() {
    return '$apiBaseUrl$apkDownloadEndpoint';
  }
  
  /// Get custom APK download URL with parameters
  static String getCustomApkUrl({
    String? version,
    String? platform,
    Map<String, String>? queryParams,
  }) {
    String url = '$apiBaseUrl$apkDownloadEndpoint';
    
    List<String> params = [];
    if (version != null) params.add('version=$version');
    if (platform != null) params.add('platform=$platform');
    
    if (queryParams != null) {
      queryParams.forEach((key, value) {
        params.add('$key=$value');
      });
    }
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    return url;
  }
}
