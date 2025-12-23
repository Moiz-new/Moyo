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
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _phoneNumberController.dispose();
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(ImageConstant.loginBgImg, fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                  MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacer(),
                        Image.asset(
                          "assets/icons/app_icon_radius.png.png",
                          height: 100.h,
                        ),
                        SizedBox(height: 20.h),
                        // Phone number TextField
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400, width: 2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                child: Image.asset(
                                  ImageConstant.phoneLogo,
                                  height: 24.h,
                                  width: 24.w,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(top: 15.h),
                                width: 200.w,
                                height: 36.h,
                                child: TextField(
                                  cursorColor: Colors.black,
                                  style: AppTextStyle.robotoMedium.copyWith(
                                    color: Colors.black,
                                    fontSize: 15.sp,
                                  ),
                                  controller: _phoneNumberController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    hintText: "Phone Number",
                                    counterText: "",
                                    hintStyle: AppTextStyle.robotoMedium
                                        .copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 15.sp,
                                    ),
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Terms and Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: SizedBox(
                                height: 18.h,
                                width: 18.w,
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
                                    color: Colors.grey.shade600,
                                    width: 2,
                                  ),
                                  materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyle.robotoRegular.copyWith(
                                    color: Colors.grey.shade700,
                                    fontSize: 12.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "By continuing, you agree to our ",
                                    ),
                                    TextSpan(
                                      text: "Terms and Conditions.",
                                      style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.black,
                                        fontWeight: FontWeight.w600,
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Terms and Conditions coming soon",
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // Primary Continue button
                        ElevatedButton(
                          onPressed: (provider.isLoading || !_isTermsAccepted)
                              ? null
                              : () => _handleContinue(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTermsAccepted
                                ? ColorConstant.appColor
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: provider.isLoading
                              ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "Continue",
                            style: AppTextStyle.robotoMedium.copyWith(
                              fontSize: 16.sp,
                              color: _isTermsAccepted
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // OR text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Continue with Google button
                        ElevatedButton(
                          onPressed: (provider.isLoading || !_isTermsAccepted)
                              ? null
                              : () => _handleGoogleSignIn(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: _isTermsAccepted
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            disabledBackgroundColor: Colors.grey.shade100,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                ImageConstant.googleLogo,
                                width: 22.w,
                                height: 22.h,
                                fit: BoxFit.cover,
                                color: _isTermsAccepted ? null : Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Continue with Google",
                                style: AppTextStyle.robotoMedium.copyWith(
                                  color: _isTermsAccepted
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }}