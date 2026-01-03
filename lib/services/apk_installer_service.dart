import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApkInstallerService {
  final Dio _dio = Dio();
  int? _cachedAndroidVersion;

  // Get Android SDK version
  Future<int> get androidVersion async {
    if (_cachedAndroidVersion != null) {
      return _cachedAndroidVersion!;
    }

    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _cachedAndroidVersion = androidInfo.version.sdkInt;
        return _cachedAndroidVersion!;
      } catch (e) {
        // Fallback to Android 10
        _cachedAndroidVersion = 29;
        return 29;
      }
    }
    return 0;
  }

  // Request all necessary permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    Map<String, bool> permissionResults = {};
    final sdkVersion = await androidVersion;

    // Storage permissions for Android 10 and below
    if (sdkVersion <= 29) {
      final storageStatus = await Permission.storage.request();
      permissionResults['storage'] = storageStatus.isGranted;
    }

    // Manage external storage for Android 11+
    if (sdkVersion >= 30) {
      final manageStorageStatus = await Permission.manageExternalStorage.request();
      permissionResults['manageExternalStorage'] = manageStorageStatus.isGranted;
      
      // If not granted, open settings
      if (!manageStorageStatus.isGranted) {
        await openAppSettings();
      }
    }

    // Notification permission for Android 13+
    if (sdkVersion >= 33) {
      final notificationStatus = await Permission.notification.request();
      permissionResults['notification'] = notificationStatus.isGranted;
    }

    // Install packages permission (required for all versions)
    final installStatus = await Permission.requestInstallPackages.request();
    permissionResults['installPackages'] = installStatus.isGranted;

    return permissionResults;
  }

  // Check if all required permissions are granted
  Future<bool> checkPermissions() async {
    bool hasStoragePermission = true;
    bool hasInstallPermission = true;
    final sdkVersion = await androidVersion;

    if (sdkVersion <= 29) {
      hasStoragePermission = await Permission.storage.isGranted;
    } else if (sdkVersion >= 30) {
      hasStoragePermission = await Permission.manageExternalStorage.isGranted;
    }

    hasInstallPermission = await Permission.requestInstallPackages.isGranted;

    return hasStoragePermission && hasInstallPermission;
  }

  // Download APK from URL
  Future<String> downloadApk({
    required String url,
    required Function(double) onProgress,
    String? fileName,
  }) async {
    try {
      final sdkVersion = await androidVersion;
      
      // Get appropriate directory based on Android version
      Directory? directory;
      if (sdkVersion >= 30) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate file name
      final apkFileName = fileName ?? 'app_${DateTime.now().millisecondsSinceEpoch}.apk';
      final filePath = '${directory.path}/$apkFileName';

      // Delete old file if exists
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Download with progress tracking
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          headers: {
            'Accept': 'application/vnd.android.package-archive',
          },
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      return filePath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  // Install APK
  Future<void> installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK file not found at: $filePath');
      }

      // Verify it's an APK file
      if (!filePath.toLowerCase().endsWith('.apk')) {
        throw Exception('File is not an APK');
      }

      // Open APK file which triggers installation
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done && result.type != ResultType.noAppToOpen) {
        throw Exception('Failed to open APK: ${result.message}');
      }
    } catch (e) {
      throw Exception('Installation failed: $e');
    }
  }

  // Download and install in one go
  Future<void> downloadAndInstall({
    required String url,
    required Function(double) onProgress,
    required Function(String) onStatusChange,
    String? fileName,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      onStatusChange('Starting download...');
      
      // Download APK
      final filePath = await downloadApk(
        url: url,
        onProgress: onProgress,
        fileName: fileName,
      );

      onStatusChange('Download complete. Installing...');

      // Install APK
      await installApk(filePath);

      onStatusChange('Installation started. Check notifications.');
    } catch (e) {
      onStatusChange('Error: $e');
      rethrow;
    }
  }

  // Get permission status summary
  Future<Map<String, String>> getPermissionStatus() async {
    Map<String, String> status = {};
    final sdkVersion = await androidVersion;

    if (sdkVersion <= 29) {
      final storage = await Permission.storage.status;
      status['Storage'] = storage.toString().split('.').last;
    }

    if (sdkVersion >= 30) {
      final manageStorage = await Permission.manageExternalStorage.status;
      status['Manage External Storage'] = manageStorage.toString().split('.').last;
    }

    if (sdkVersion >= 33) {
      final notification = await Permission.notification.status;
      status['Notification'] = notification.toString().split('.').last;
    }

    final installPackages = await Permission.requestInstallPackages.status;
    status['Install Packages'] = installPackages.toString().split('.').last;

    return status;
  }

  // Clean up old APK files
  Future<void> cleanupOldApks() async {
    try {
      final sdkVersion = await androidVersion;
      Directory? directory;
      if (sdkVersion >= 30) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
      }

      if (directory != null && await directory.exists()) {
        final files = directory.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.apk')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
