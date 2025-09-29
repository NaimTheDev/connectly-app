import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for launching external URLs with consistent error handling
class UrlLauncherService {
  /// Launches a join URL (Zoom, Teams, etc.) in an external application
  /// Shows user-friendly error messages via SnackBar if launch fails
  static Future<void> launchJoinUrl(
    BuildContext context,
    String joinUrl,
  ) async {
    try {
      final uri = Uri.parse(joinUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch the meeting URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching meeting URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Launches a Calendly URL in an external application
  /// Shows user-friendly error messages via SnackBar if launch fails
  static Future<void> launchCalendlyUrl(
    BuildContext context,
    String calendlyUrl,
  ) async {
    try {
      final uri = Uri.parse(calendlyUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch the Calendly URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching Calendly URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
