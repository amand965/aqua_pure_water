import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !updateInfo.isForceUpdate,
        child: UpdateDialog(updateInfo: updateInfo),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  String _downloadProgress = '0%';
  double _progressValue = 0.0;
  String _statusMessage = '';
  bool _hasError = false;

  Future<void> _startUpdate() async {
    if (widget.updateInfo.downloadUrl.isEmpty) {
      _showError('Invalid download URL provided.');
      return;
    }

    setState(() {
      _isDownloading = false;
      _statusMessage = 'Opening browser download...';
    });

    try {
      final Uri url = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showError('Could not launch download URL.');
      }
    } catch (e) {
      _showError('Download failed: $e');
    }
  }

  Future<void> _fallbackToBrowserDownload(String reason) async {
    debugPrint("$reason. Fallback to external browser launcher.");
    if (!mounted) return;
    
    setState(() {
      _isDownloading = false;
      _hasError = true;
      _statusMessage = 'Redirecting to direct download link...';
    });

    try {
      final Uri url = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch download URL.');
      }
    } catch (e) {
      _showError('Direct download failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _hasError = true;
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 4,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'New Version Available! 🚀',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${widget.updateInfo.latestVersion} is ready (Current: v${widget.updateInfo.currentVersion})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Release Notes Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's New:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Download Progress Indicator (when downloading)
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryBlue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    _downloadProgress,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_hasError) ...[
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.statusOverdue),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    if (!widget.updateInfo.isForceUpdate)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDownloading ? null : () => Navigator.pop(context),
                          child: const Text('LATER'),
                        ),
                      ),
                    if (!widget.updateInfo.isForceUpdate) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDownloading ? null : _startUpdate,
                        child: Text(_isDownloading ? 'DOWNLOADING' : 'AUTO UPDATE'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: const Text('Download via Browser / Chrome', style: TextStyle(fontSize: 12)),
                  onPressed: _isDownloading ? null : () => _fallbackToBrowserDownload('Manual Browser Download Triggered'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
