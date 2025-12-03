import 'package:first_flutter/baseControllers/NavigationController/navigation_controller.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/constants/imgConstant/img_constant.dart';
import 'package:first_flutter/constants/utils/app_text_style.dart';
import 'package:first_flutter/screens/commonOnboarding/otpScreen/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../otpScreen/EmailVerificationScreen.dart';
import 'MobileVerificationScreen.dart';
import 'login_screen_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();

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

  void _handleGoogleSignIn(BuildContext context, LoginProvider provider) async {
    // In your login screen or wherever you call signInWithGoogle
    // Replace your existing onSuccess callback with this:

    await provider.signInWithGoogle((data) {
      final needsMobileVerification = data['needsMobileVerification'] ?? false;
      final needsEmailVerification = data['needsEmailVerification'] ?? false;
      final userEmail = data['user']?['email'];

      if (needsMobileVerification) {
        // Navigate to mobile verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MobileVerificationScreen(),
          ),
        );
      } else if (needsEmailVerification && userEmail != null) {
        // Navigate to email verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(userEmail: userEmail),
          ),
        );
      } else {
        // Navigate to home
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/UserCustomBottomNav",
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    // Show error message if any
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
      // Important: Allows screen to resize when keyboard appears
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(ImageConstant.loginBgImg, fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              // Wraps content to make it scrollable when keyboard appears
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
                        // MOYO Text at top
                        Image.asset(
                          "assets/icons/app_icon_radius.png.png",
                          height: 100.h,
                        ),
                        SizedBox(height: 20.h),
                        // Phone number TextField
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.grey, width: 2),
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
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(top: 15.h),
                                width: 200.w,
                                height: 36.h,
                                child: TextField(
                                  cursorColor: Colors.white,
                                  style: AppTextStyle.robotoMedium.copyWith(
                                    color: Colors.white,
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
                                          color: Colors.white,
                                          fontSize: 15.sp,
                                        ),
                                    fillColor: Colors.black,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
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
                        SizedBox(height: 24.h),
                        // Primary Continue button
                        ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _handleContinue(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.appColor,
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
                                    color: Colors.white,
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
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Continue with Google button
                        ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _handleGoogleSignIn(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                ImageConstant.googleLogo,
                                width: 22.w,
                                height: 22.h,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Continue with Google",
                                style: AppTextStyle.robotoMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Terms & Conditions at bottom
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h, top: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: Text(
                                  "By continuing, you agree to our",
                                  style: AppTextStyle.robotoRegular.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  debugPrint("Terms & Conditions pressed");
                                },
                                child: Text(
                                  "Terms and Conditions.",
                                  style: AppTextStyle.robotoRegular.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
  }
}
