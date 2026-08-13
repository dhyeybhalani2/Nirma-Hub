import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class UpdateService {
  static final _supabase = Supabase.instance.client;

  // Global state for background downloads
  static final ValueNotifier<double?> downloadProgress = ValueNotifier(null);
  static final ValueNotifier<String> downloadStatus = ValueNotifier("Preparing...");
  static OverlayEntry? _overlayEntry;

  static String? _cachedVersionName;
  static String? _cachedReleaseNotes;
  static String? _cachedDownloadUrl;
  static bool _cachedIsMandatory = false;

  /// Checks if an update is available and shows a dialog if necessary.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version info
      final packageInfo = await PackageInfo.fromPlatform();
      final int currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      // Get latest update from Supabase
      final response = await _supabase
          .from('app_updates')
          .select()
          .order('created_at', ascending: false) // Order by latest created instead of version_code
          .limit(1);

      if (response.isEmpty) return;

      final latestUpdate = response.first;
      final int latestVersionCode = int.tryParse(latestUpdate['version_code'].toString()) ?? 0;
      
      _cachedVersionName = latestUpdate['version_name'].toString();
      _cachedReleaseNotes = latestUpdate['release_notes']?.toString() ?? 'A new version is available!';
      _cachedDownloadUrl = latestUpdate['download_url']?.toString() ?? 'https://nirma-hub.online/app';
      _cachedIsMandatory = latestUpdate['is_mandatory'] == true;

      final String currentVersion = packageInfo.version; // e.g. "1.0.0"

      if (_isUpdateAvailable(currentVersion, _cachedVersionName!)) {
        if (context.mounted) {
          _showUpdateBottomSheet(context);
        }
      }
    } catch (e) {
      print('Failed to check for updates: $e');
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      List<int> currentParts = currentVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> latestParts = latestVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      
      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static void _showUpdateBottomSheet(BuildContext context) async {
    final safeContext = navigatorKey.currentContext ?? context;
    await showModalBottomSheet(
      context: safeContext,
      isScrollControlled: true,
      isDismissible: !_cachedIsMandatory,
      enableDrag: !_cachedIsMandatory,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _UpdateBottomSheetWidget(
          versionName: _cachedVersionName!,
          releaseNotes: _cachedReleaseNotes!,
          downloadUrl: _cachedDownloadUrl!,
          isMandatory: _cachedIsMandatory,
        );
      },
    );
    // If the download is still happening when they close the bottom sheet, bring the overlay back
    if (downloadProgress.value != null && downloadProgress.value != 1.0) {
      _showOverlay(safeContext);
    }
  }

  static void _startBackgroundDownload(BuildContext context, String versionName, String downloadUrl) async {
    // If already downloading, don't start again
    if (downloadProgress.value != null) return;
    
    downloadProgress.value = 0.0;
    downloadStatus.value = "Preparing...";
    
    _showOverlay(context);

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/NirmaHub_Update_$versionName.apk';

      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
            downloadStatus.value = "Downloading Update... ${(received / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB";
          }
        },
      );

      downloadProgress.value = 1.0;
      downloadStatus.value = "Download Complete! Installing...";
      
      await Future.delayed(const Duration(milliseconds: 1500));
      _removeOverlay();

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open installer: ${result.message}')),
          );
        }
      }
    } catch (e) {
      _removeOverlay();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      downloadProgress.value = null;
    }
  }

  static void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 80, // Moved up to clear bottom navigation bar
          left: 20,
          right: 20,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: ValueListenableBuilder<double?>(
              valueListenable: downloadProgress,
              builder: (context, progress, child) {
                final isCompleted = progress == 1.0;
                return GestureDetector(
                  onTap: () {
                    if (!isCompleted) {
                      _removeOverlay();
                      _showUpdateBottomSheet(navigatorKey.currentContext ?? context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.withOpacity(0.1) : const Color(0xFFC62828).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.downloading_rounded, 
                            color: isCompleted ? Colors.green : const Color(0xFFC62828), 
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: downloadStatus,
                                builder: (context, status, child) {
                                  return Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: Color(0xFF1A2B48),
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? Colors.green : const Color(0xFFC62828)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        );
      },
    );
    
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
    } else {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _UpdateBottomSheetWidget extends StatelessWidget {
  final String versionName;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;

  const _UpdateBottomSheetWidget({
    Key? key,
    required this.versionName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isMandatory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory,
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              
              // Title
              Text(
                "Update Available",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B48),
                ),
              ),
              SizedBox(height: 8),
              
              // Subtitle
              Text(
                "Version $versionName is ready to install.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20),
              
              // Release Notes Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 6),
                        Text(
                          "What's New",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (isMandatory) ...[
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This is a required update.",
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              ValueListenableBuilder<double?>(
                valueListenable: UpdateService.downloadProgress,
                builder: (context, progress, child) {
                  // If it's currently downloading
                  if (progress != null) {
                    final isCompleted = progress == 1.0;
                    return Column(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: UpdateService.downloadStatus,
                          builder: (context, status, child) {
                            return Text(
                              status,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? Colors.green : const Color(0xFFC62828)
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Close button for the bottom sheet, so they can return to using the app
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Minimize to Background",
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // If it's NOT downloading
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC62828), Color(0xFFE53935)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            UpdateService._startBackgroundDownload(context, versionName, downloadUrl);
                          },
                          child: Text(
                            "Update directly via App",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          if (!isMandatory) ...[
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Later",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Expanded(
                            flex: isMandatory ? 1 : 2,
                            child: TextButton(
                              onPressed: () async {
                                final Uri url = Uri.parse(downloadUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                ),
                              ),
                              child: Text(
                                "From Website",
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
