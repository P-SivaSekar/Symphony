import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Current app version constant
  static const String currentAppVersion = "1.0.0.2";

  // URL to get the latest version metadata (Firebase Hosting is primary)
  static const String primaryVersionUrl = "https://symphony-music-app-6eddc.web.app/version.json";
  static const String fallbackVersionUrl = "https://raw.githubusercontent.com/P-SivaSekar/Symphony/main/web/version.json";

  /// Compares two version strings segment by segment (e.g. "1.0.0.0" vs "1.0.0.1")
  /// Returns -1 if v1 < v2, 1 if v1 > v2, 0 if equal.
  static int compareVersions(String v1, String v2) {
    List<int> p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    int length = p1.length > p2.length ? p1.length : p2.length;
    for (int i = 0; i < length; i++) {
      int val1 = i < p1.length ? p1[i] : 0;
      int val2 = i < p2.length ? p2[i] : 0;
      if (val1 < val2) return -1;
      if (val1 > val2) return 1;
    }
    return 0;
  }

  /// Checks if an update is required and displays an unskippable update popup if so.
  static Future<void> checkVersion(BuildContext context) async {
    try {
      Map<String, dynamic>? data;
      try {
        final response = await http.get(Uri.parse(primaryVersionUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          data = jsonDecode(response.body);
        }
      } catch (e) {
        print("Primary version check failed, attempting fallback: $e");
      }

      if (data == null) {
        final response = await http.get(Uri.parse(fallbackVersionUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          data = jsonDecode(response.body);
        }
      }

      if (data != null) {
        final String minRequiredVersion = data['min_required_version'] ?? "1.0.0.1";
        final String updateUrl = data['update_url'] ?? "https://github.com/P-SivaSekar/Symphony";

        // Check if current version is less than minimum required version
        // or explicitly equal to 1.0.0.0 as requested
        final isOldVersion = compareVersions(currentAppVersion, minRequiredVersion) < 0;
        final isExplicit1000 = currentAppVersion == "1.0.0.0";

        if (isOldVersion || isExplicit1000) {
          _showUpdateDialog(context, minRequiredVersion, updateUrl);
        }
      }
    } catch (e) {
      print("Error during version check: $e");
    }
  }

  /// Displays the unskippable update dialog
  static void _showUpdateDialog(BuildContext context, String newVersion, String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Unskippable
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false, // Prevents Android back button from dismissing
          child: AlertDialog(
            backgroundColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
            ),
            title: Row(
              children: const [
                Icon(Icons.system_update_alt, color: Colors.cyanAccent),
                SizedBox(width: 10),
                Text(
                  "Update Required",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              "A new version of Symphony (v$newVersion) is available. You must update the app to continue listening to music.",
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
            actions: [
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(updateUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        // Fallback launch
                        await launchUrl(uri);
                      }
                    },
                    child: const Text(
                      "Update from GitHub",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
