import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForceUpdate;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForceUpdate,
  });
}

class AppUpdateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if a new version is available on Firestore
  Future<AppUpdateInfo?> checkAppUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final DocumentSnapshot doc = await _db
          .collection('app_config')
          .doc('update_info')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final String latestVersion = data['latestVersion'] ?? currentVersion;
      final String downloadUrl = data['downloadUrl'] ?? '';
      final String releaseNotes = data['releaseNotes'] ?? 'Bug fixes & performance improvements.';
      final bool forceUpdate = data['forceUpdate'] ?? false;

      final bool hasUpdate = isVersionGreater(latestVersion, currentVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        isForceUpdate: forceUpdate,
      );
    } catch (e) {
      debugPrint("Error checking app update: $e");
      return null;
    }
  }

  // Compare semantic version numbers (e.g., "1.0.1" > "1.0.0")
  bool isVersionGreater(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      int maxLength = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      for (int i = 0; i < maxLength; i++) {
        int latestNum = i < latestParts.length ? latestParts[i] : 0;
        int currentNum = i < currentParts.length ? currentParts[i] : 0;

        if (latestNum > currentNum) return true;
        if (latestNum < currentNum) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
