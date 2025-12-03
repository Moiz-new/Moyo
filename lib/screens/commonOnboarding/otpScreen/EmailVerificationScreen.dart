// email_verification_screen.dart
import 'package:first_flutter/baseControllers/NavigationController/navigation_controller.dart';
import 'package:first_flutter/constants/imgConstant/img_constant.dart';
import 'package:first_flutter/constants/utils/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../constants/colorConstant/color_constant.dart';
import 'otp_screen_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? userEmail;

  const EmailVerificationScreen({super.key, this.userEmail});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late TextEditingController emailController;
  late List<TextEditingController> emailOtpControllers;
  late List<FocusNode> emailOtpFocusNodes;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _otpSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.userEmail ?? '');
    emailOtpControllers = List.generate(6, (_) => TextEditingController());
    emailOtpFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    emailController.dispose();
    _scrollController.dispose();
    for (var controller in emailOtpControllers) {
      controller.dispose();
    }
    for (var focusNode in emailOtpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getEmailOtp() {
    return emailOtpControllers.map((c) => c.text).join();
  }

  /// Scroll to OTP section and focus first field
  void _scrollToOtpSection() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _otpSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _otpSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );

        // Focus on first OTP field
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            emailOtpFocusNodes[0].requestFocus();
          }
        });
      }
    });
  }

  /// Get FCM device token
  Future<String?> _getDeviceToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');
      return fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
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
          controller: emailOtpControllers[index],
          focusNode: emailOtpFocusNodes[index],
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
              emailOtpFocusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              emailOtpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  Future<void> _sendEmailOtp() async {
    final provider = context.read<OtpScreenProvider>();
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final sent = await provider.sendEmailOtp(email: email);

    if (sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('OTP sent to $email'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Scroll to OTP section after successful send
      _scrollToOtpSection();
    }
  }

  Future<void> _verifyEmailOtp() async {
    final provider = context.read<OtpScreenProvider>();
    final email = emailController.text.trim();
    final otp = _getEmailOtp();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final verified = await provider.verifyEmailOtp(email: email, otp: otp);

    if (verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Email verified successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Update device token after successful email verification
      await _updateDeviceToken();

      // Navigate to home after verification
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/UserCustomBottomNav",
            (route) => false,
          );
        }
      });
    }
  }

  /// Update device token after email verification
  Future<void> _updateDeviceToken() async {
    final provider = context.read<OtpScreenProvider>();

    try {
      // Get FCM device token
      final deviceToken = await _getDeviceToken();

      if (deviceToken != null && deviceToken.isNotEmpty) {
        print('Updating device token: $deviceToken');

        // Update device token via API
        final updated = await provider.updateDeviceToken(
          deviceToken: deviceToken,
        );

        if (updated) {
          print('Device token updated successfully');
        } else {
          print('Failed to update device token');
        }
      } else {
        print('No device token available');
      }
    } catch (e) {
      print('Error in _updateDeviceToken: $e');
      // Don't show error to user, just log it
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
            controller: _scrollController,
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
                      Icons.mark_email_read_outlined,
                      size: 60,
                      color: ColorConstant.appColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    "Verify Your Email",
                    style: AppTextStyle.robotoBold.copyWith(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "We'll send a verification code to\nyour email address",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.robotoRegular.copyWith(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email TextField
                  // Email TextField
                  Container(
                    padding: EdgeInsets.all(8),
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
                            Icons.email_outlined,
                            color: ColorConstant.appColor,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(top: 15),
                            height: 36,
                            child: TextField(
                              controller: emailController,
                              cursorColor: Colors.white,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyle.robotoMedium.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: "Email Address",
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

                  // Error message for email
                  Consumer<OtpScreenProvider>(
                    builder: (context, provider, _) {
                      if (provider.emailErrorMessage != null &&
                          !provider.emailOtpSent) {
                        return Container(
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
                                  provider.emailErrorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 8),

                  // Send OTP Button
                  Consumer<OtpScreenProvider>(
                    builder: (context, provider, _) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isEmailOtpLoading
                            ? null
                            : _sendEmailOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.appColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        icon: provider.isEmailOtpLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                provider.emailOtpSent
                                    ? Icons.refresh
                                    : Icons.send,
                                size: 20,
                              ),
                        label: Text(
                          provider.emailOtpSent ? "Resend OTP" : "Send OTP",
                          style: AppTextStyle.robotoMedium.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // OTP Input Section
                  Consumer<OtpScreenProvider>(
                    builder: (context, provider, _) {
                      if (!provider.emailOtpSent) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        key: _otpSectionKey,
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
                            "Code sent to your email",
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
                          if (provider.emailErrorMessage != null &&
                              provider.emailOtpSent)
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
                                      provider.emailErrorMessage!,
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
                              onPressed: provider.isEmailOtpVerifying
                                  ? null
                                  : _verifyEmailOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              icon: provider.isEmailOtpVerifying
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
                                "Verify Email",
                                style: AppTextStyle.robotoMedium.copyWith(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
