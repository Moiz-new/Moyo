// mobile_verification_screen.dart
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:first_flutter/baseControllers/NavigationController/navigation_controller.dart';
import 'package:first_flutter/constants/imgConstant/img_constant.dart';
import 'package:first_flutter/constants/utils/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/colorConstant/color_constant.dart';
import '../otpScreen/EmailVerificationScreen.dart';

class MobileVerificationScreen extends StatefulWidget {
  const MobileVerificationScreen({super.key});

  @override
  State<MobileVerificationScreen> createState() =>
      _MobileVerificationScreenState();
}

class _MobileVerificationScreenState extends State<MobileVerificationScreen> {
  late TextEditingController mobileController;
  late List<TextEditingController> mobileOtpControllers;
  late List<FocusNode> mobileOtpFocusNodes;
  bool otpSent = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    mobileController = TextEditingController();
    mobileOtpControllers = List.generate(6, (_) => TextEditingController());
    mobileOtpFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    mobileController.dispose();
    for (var controller in mobileOtpControllers) {
      controller.dispose();
    }
    for (var focusNode in mobileOtpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getMobileOtp() {
    return mobileOtpControllers.map((c) => c.text).join();
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 50,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: mobileOtpControllers[index],
          focusNode: mobileOtpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTextStyle.robotoBold.copyWith(
            fontSize: 24,
            color: Colors.black87,
          ),
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: "",
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              mobileOtpFocusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              mobileOtpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  Future<void> _sendMobileOtp() async {
    final mobile = mobileController.text.trim();

    if (mobile.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your mobile number';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mobile.length < 10) {
      setState(() {
        errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('$base_url/api/auth/number-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'mobile': mobile}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          otpSent = true;
          isLoading = false;
          errorMessage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(responseData['message'] ?? 'OTP sent to $mobile'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyMobileOtp() async {
    final mobile = mobileController.text.trim();
    final otp = _getMobileOtp();

    if (otp.length != 6) {
      setState(() {
        errorMessage = 'Please enter complete 6-digit OTP';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('$base_url/api/auth/number-verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'mobile': mobile, 'otp': otp}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
          errorMessage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    responseData['message'] ?? 'Mobile verified successfully!',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          // Get email verification status from SharedPreferences
          final isEmailVerified = prefs.getBool('is_email_verified') ?? false;
          final userEmail = prefs.getString('user_email');

          print('Email verified status: $isEmailVerified');
          print('User email: $userEmail');

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              if (!isEmailVerified &&
                  userEmail != null &&
                  userEmail.isNotEmpty) {
                // Navigate to email verification screen
                print('Navigating to email verification screen');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmailVerificationScreen(userEmail: userEmail),
                  ),
                );
              } else {
                // Navigate to home
                print('Navigating to home screen');
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/UserCustomBottomNav",
                  (route) => false,
                );
              }
            }
          });
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to verify OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            navigationService.pop();
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ImageConstant.loginBgImg, fit: BoxFit.cover),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 60,
                      color: ColorConstant.appColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    "Verify Your Mobile",
                    style: AppTextStyle.robotoBold.copyWith(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "We'll send a verification code to\nyour mobile number",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.robotoRegular.copyWith(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mobile TextField
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          child: Icon(
                            Icons.phone,
                            color: ColorConstant.appColor,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(top: 15),
                            height: 36,
                            child: TextField(
                              controller: mobileController,
                              cursorColor: Colors.white,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: AppTextStyle.robotoMedium.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: "Mobile Number",
                                counterText: "",
                                hintStyle: AppTextStyle.robotoMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                fillColor: Colors.black,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message for mobile
                  if (errorMessage != null && !otpSent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _sendMobileOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.appColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              otpSent ? Icons.refresh : Icons.send,
                              size: 20,
                            ),
                      label: Text(
                        otpSent ? "Resend OTP" : "Send OTP",
                        style: AppTextStyle.robotoMedium.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // OTP Input Section
                  if (otpSent)
                    Column(
                      children: [
                        const SizedBox(height: 32),

                        // OTP Label
                        Text(
                          "Enter 6-Digit Code",
                          style: AppTextStyle.robotoBold.copyWith(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Code sent to your mobile",
                          style: AppTextStyle.robotoRegular.copyWith(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // OTP Fields
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => _buildOtpField(index),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Error message for OTP verification
                        if (errorMessage != null && otpSent)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _verifyMobileOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            icon: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.verified, size: 20),
                            label: Text(
                              "Verify Mobile",
                              style: AppTextStyle.robotoMedium.copyWith(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
