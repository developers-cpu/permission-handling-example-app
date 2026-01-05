import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
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
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Request all necessary permissions based on Android version
  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _statusMessage = 'Checking permissions...';
    });

    try {
      // Request install packages permission (required for all versions)
      final installStatus = await Permission.requestInstallPackages.request();

      // Try to request storage-related permissions
      // We'll handle each one individually to avoid the "pending" error

      // Try storage permission first (for older Android)
      try {
        await Permission.storage.request();
      } catch (e) {
        print('Storage permission not available: $e');
      }

      // Try manage external storage (for Android 11+)
      PermissionStatus? manageStorageStatus;
      try {
        manageStorageStatus = await Permission.manageExternalStorage.request();
      } catch (e) {
        print('Manage external storage permission not available: $e');
      }

      setState(() {
        if (installStatus.isGranted) {
          _statusMessage = 'Install permission granted. Ready to download.';
        } else {
          _statusMessage = 'Install permission required. Please grant it.';
        }
      });

      // If manage external storage is denied, open settings
      if (manageStorageStatus != null && manageStorageStatus.isDenied) {
        await openAppSettings();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Permission check error: $e';
      });
      print('Permission error: $e');
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
      // Get download directory - use app-specific directory which doesn't require special permissions
      final directory = await getApplicationDocumentsDirectory();

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

      // Install using flutter_app_installer
      final installer = FlutterAppInstaller();
      await installer.installApk(filePath: filePath);

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                    Text('Platform: ${Platform.operatingSystem}'),
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
