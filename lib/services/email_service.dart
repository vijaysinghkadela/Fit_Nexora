import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Provider for the EmailService
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

/// Service to handle sending transactional emails via Resend's REST API.
class EmailService {
  final String _baseUrl = 'https://api.resend.com/emails';

  /// Sends an email using Resend.
  ///
  /// [to] The recipient email address.
  /// [subject] The subject line of the email.
  /// [htmlBody] The HTML content of the email.
  /// [from] The sender email address. Must be a verified domain in Resend.
  /// Defaults to 'FitNexora <onboarding@resend.dev>' for testing purposes.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String from = 'FitNexora <onboarding@resend.dev>',
  }) async {
    if (AppConfig.resendApiKey.isEmpty) {
      debugPrint('[EmailService] Attempted to send email but RESEND_API_KEY is empty.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppConfig.resendApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': from,
          'to': [to],
          'subject': subject,
          'html': htmlBody,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[EmailService] Email sent successfully to $to');
        return true;
      } else {
        debugPrint('[EmailService] Failed to send email. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailService] Error sending email: $e');
      return false;
    }
  }
}
