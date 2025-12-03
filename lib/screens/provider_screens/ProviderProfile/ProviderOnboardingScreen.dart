import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProviderOnboardingDialog extends StatelessWidget {
  const ProviderOnboardingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => const ProviderOnboardingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstant.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrangeFade,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_rounded,
                size: 60,
                color: ColorConstant.moyoOrange,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Welcome to Provider Mode!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorConstant.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Please complete your profile to start offering services',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7A7A7A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Complete Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamed(context, '/editProviderProfile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.moyoOrange,
                  foregroundColor: ColorConstant.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Complete Profile',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ColorConstant.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Usage in your code:
// Instead of Navigator.pushNamed(context, "/ProviderOnboarding");
// Use: ProviderOnboardingDialog.show(context);
