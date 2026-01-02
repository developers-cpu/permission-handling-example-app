import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin/install_plugin.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APK Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ApkInstallerHome(),
    );
  }
}

class ApkInstallerHome extends StatefulWidget {
  const ApkInstallerHome({super.key});

  @override
  State<ApkInstallerHome> createState() => _ApkInstallerHomeState();
}

class _ApkInstallerHomeState extends State<ApkInstallerHome> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Ready to download';
  String _apkUrl = '';
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Check Android version
  int get androidVersion {
    if (Platform.isAndroid) {
      return int.tryParse(Platform.version.split('.').first) ?? 0;
    }
    return 0;
  }

  // Request all necessary permissions based on Android version
  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _statusMessage = 'Checking permissions...';
    });

    Map<Permission, PermissionStatus> statuses = {};

    // Android 10 (API 29) and below - Storage permissions
    if (androidVersion <= 29) {
      statuses[Permission.storage] = await Permission.storage.request();
    }

    // Android 11 (API 30) and above - Manage external storage
    if (androidVersion >= 30) {
      statuses[Permission.manageExternalStorage] = 
          await Permission.manageExternalStorage.request();
    }

    // Android 13 (API 33) and above - Notification permission
    if (androidVersion >= 33) {
      statuses[Permission.notification] = await Permission.notification.request();
    }

    // Install packages permission (all versions)
    statuses[Permission.requestInstallPackages] = 
        await Permission.requestInstallPackages.request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    setState(() {
      if (allGranted) {
        _statusMessage = 'All permissions granted. Ready to download.';
      } else {
        _statusMessage = 'Some permissions denied. App may not work properly.';
      }
    });

    // If manage external storage is not granted, open settings
    if (androidVersion >= 30) {
      if (!await Permission.manageExternalStorage.isGranted) {
        await openAppSettings();
      }
    }
  }

  // Download APK from URL
  Future<void> _downloadAndInstallApk(String url) async {
    if (url.isEmpty) {
      _showSnackBar('Please enter a valid URL');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Starting download...';
    });

    try {
      // Get download directory
      Directory? directory;
      if (androidVersion >= 30) {
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

      final filePath = '${directory.path}/downloaded_app.apk';

      // Delete old APK if exists
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Download APK
      Dio dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
              _statusMessage = 
                  'Downloading: ${(received / total * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Download complete. Installing...';
      });

      // Install APK
      await _installApk(filePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error: $e';
      });
      _showSnackBar('Download failed: $e');
    }
  }

  // Install APK
  Future<void> _installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK file not found');
      }

      // Install using install_plugin
      await InstallPlugin.install(filePath);

      setState(() {
        _isDownloading = false;
        _statusMessage = 'Installation started. Check notifications.';
      });

      _showSnackBar('Installation prompt opened');
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Installation error: $e';
      });
      _showSnackBar('Installation failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK Installer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // URL input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'APK Download URL',
                hintText: 'https://example.com/app.apk',
                border: OutlineInputBorder(),
              ),
              enabled: !_isDownloading,
            ),
            const SizedBox(height: 20),

            // Download button
            ElevatedButton.icon(
              onPressed: _isDownloading
                  ? null
                  : () => _downloadAndInstallApk(_urlController.text),
              icon: const Icon(Icons.download),
              label: const Text('Download & Install'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),

            // Permission check button
            OutlinedButton.icon(
              onPressed: _checkAndRequestPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Check Permissions'),
            ),
            const SizedBox(height: 20),

            // Android version info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Device Info',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Android Version: ${Platform.version}'),
                    Text('SDK Level: $androidVersion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Grant all required permissions\n'
                        '2. Enter the APK download URL from your API\n'
                        '3. Tap "Download & Install"\n'
                        '4. Wait for download to complete\n'
                        '5. Follow installation prompts\n\n'
                        'Supported Android Versions:\n'
                        '• Android 10 (API 29)\n'
                        '• Android 11 (API 30)\n'
                        '• Android 12 (API 31)\n'
                        '• Android 13 (API 33)\n'
                        '• Android 14 (API 34)\n'
                        '• Android 15 (API 35)\n'
                        '• Android 16 (API 35+)\n\n'
                        'Required Permissions:\n'
                        '• Internet access\n'
                        '• Storage access\n'
                        '• Install packages\n'
                        '• Notifications (Android 13+)',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
