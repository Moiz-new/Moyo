// app_signature_helper.dart
// Create this file in your lib folder
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class AppSignatureHelper {
  static String? _cachedSignature;

  /// Get app signature (cached after first call)
  static Future<String?> getAppSignature() async {
    if (_cachedSignature != null) {
      return _cachedSignature;
    }

    try {
      final signature = await SmsAutoFill().getAppSignature;
      _cachedSignature = signature;

      print('==========================================');
      print('APP SIGNATURE FOR SMS AUTO-FILL:');
      print(signature ?? 'Not available');
      print('==========================================');
      print('Share this signature with your backend team.');
      print('SMS format should be:');
      print('Your OTP is: 123456');
      print(signature ?? '[SIGNATURE]');
      print('==========================================');

      return signature;
    } catch (e) {
      print('Error getting app signature: $e');
      return null;
    }
  }

  /// Display signature in a dialog (for debugging)
  static Future<void> showSignatureDialog(context) async {
    final signature = await getAppSignature();

    if (signature != null && signature.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App Signature'),
          content: SelectableText(
            signature,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App Signature'),
          content: const Text(
            'App signature not available.\n\n'
                'This usually happens in debug mode or emulator.\n'
                'Build a release APK to get the signature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}