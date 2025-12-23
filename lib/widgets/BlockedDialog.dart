import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colorConstant/color_constant.dart';

class BlockedDialog extends StatelessWidget {
  const BlockedDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const BlockedDialog(),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.darkPrimary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstant.moyoOrange,
                  ColorConstant.moyoOrange.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstant.moyoOrange.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.block_rounded,
              color: ColorConstant.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorConstant.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ColorConstant.moyoOrangeFade,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Admin Blocked You',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstant.moyoOrange,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Your account has been blocked by the administrator. Please contact support for assistance.',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstant.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Clear all SharedPreferences
                await _clearAllData();

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: ColorConstant.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: ColorConstant.moyoOrange.withOpacity(0.4),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}