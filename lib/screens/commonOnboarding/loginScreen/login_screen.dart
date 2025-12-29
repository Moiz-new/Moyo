import 'package:first_flutter/baseControllers/NavigationController/navigation_controller.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/constants/imgConstant/img_constant.dart';
import 'package:first_flutter/constants/utils/app_text_style.dart';
import 'package:first_flutter/screens/commonOnboarding/otpScreen/otp_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../NotificationService.dart';
import '../../provider_screens/LegalDocumentScreen.dart';
import '../../provider_screens/TermsandConditions.dart';
import '../otpScreen/EmailVerificationScreen.dart';
import 'MobileVerificationScreen.dart';
import 'login_screen_provider.dart';
import 'package:first_flutter/screens/commonOnboarding/otpScreen/otp_screen_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handleContinue(BuildContext context, LoginProvider provider) {
    final phoneNumber = _phoneNumberController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your phone number"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please accept Terms and Conditions"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    provider.sendOtp(phoneNumber, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phoneNumber: _phoneNumberController.text.toString().trim(),
          ),
        ),
      );
    });
  }

  Future<void> _setupNotificationsAndNavigate() async {
    final provider = context.read<OtpScreenProvider>();

    try {
      print('=== Setting up notifications ===');

      final permissionGranted =
      await NotificationService.requestNotificationPermission(context);

      if (permissionGranted) {
        print('✓ Notification permission granted');

        final deviceToken = await NotificationService.getDeviceToken();

        if (deviceToken != null && deviceToken.isNotEmpty) {
          print('✓ Device token obtained: ${deviceToken.substring(0, 20)}...');

          final updated = await provider.updateDeviceToken(
            deviceToken: deviceToken,
          );

          if (updated) {
            print('✓ Device token updated successfully');
          } else {
            print('⚠ Failed to update device token on server');
          }
        } else {
          print('⚠ No device token available');
        }
      } else {
        print('✗ User declined notification permission');
      }
    } catch (e) {
      print('Error in notification setup: $e');
    }

    if (mounted) {
      print('=== Navigating to home screen ===');
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/UserCustomBottomNav",
            (route) => false,
      );
    }
  }

  void _handleGoogleSignIn(BuildContext context, LoginProvider provider) async {
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please accept Terms and Conditions"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.signInWithGoogle((data) async {
      final needsMobileVerification = data['needsMobileVerification'] ?? false;
      final needsEmailVerification = data['needsEmailVerification'] ?? false;
      final userEmail = data['user']?['email'];

      await _setupNotificationsAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Top Image Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                child: Image.asset(ImageConstant.loginBgImg, fit: BoxFit.cover),
              ),
            ),

            // Bottom Content Section
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 30.h),

                      // Title
                      Text(
                        "Find Verified and Professional Services",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Log in or sign up text
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Log in or sign up",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22.h),

                      // Phone Number Input
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            // Country Code
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                children: [
                                  Text("🇮🇳", style: TextStyle(fontSize: 20.sp)),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey.shade600,
                                    size: 24.sp,
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              width: 1,
                              height: 32.h,
                              color: Colors.grey.shade300,
                            ),

                            SizedBox(width: 12.w),

                            // Country Code Text
                            Text(
                              "+91",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // Phone Number TextField
                            Expanded(
                              child: TextField(
                                controller: _phoneNumberController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter Phone Number",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  counterText: "",
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Padding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: Checkbox(
                                value: _isTermsAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _isTermsAccepted = value ?? false;
                                  });
                                },
                                activeColor: ColorConstant.appColor,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "By continuing, you agree to our ",
                                    ),
                                    TextSpan(
                                      text: "Terms of Service",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TermsandConditions(
                                                    type: "terms",
                                                    roles: [""],
                                                  ),
                                            ),
                                          );
                                        },
                                    ),
                                    TextSpan(text: "  "),
                                    TextSpan(
                                      text: "Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Navigate to Privacy Policy
                                        },
                                    ),
                                    TextSpan(text: "  "),
                                    TextSpan(
                                      text: "Content Policy",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Navigate to Content Policy
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: (provider.isLoading || !_isTermsAccepted)
                              ? null
                              : () => _handleContinue(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTermsAccepted
                                ? ColorConstant.appColor
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                          child: provider.isLoading
                              ? SizedBox(
                            height: 24.h,
                            width: 24.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: _isTermsAccepted
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "or",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Social Login Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Button
                          GestureDetector(
                            onTap: (provider.isLoading || !_isTermsAccepted)
                                ? null
                                : () => _handleGoogleSignIn(context, provider),
                            child: Container(
                              width: 64.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  ImageConstant.googleLogo,
                                  width: 28.w,
                                  height: 28.h,
                                  fit: BoxFit.contain,
                                  color: _isTermsAccepted ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
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
}