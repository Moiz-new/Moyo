// otp_screen.dart - WITH AUTO-FILL FEATURE AND REFERRAL CHECK
import 'package:first_flutter/baseControllers/NavigationController/navigation_controller.dart';
import 'package:first_flutter/constants/imgConstant/img_constant.dart';
import 'package:first_flutter/constants/utils/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../NotificationService.dart';
import '../../../constants/colorConstant/color_constant.dart';
import '../../../constants/utils/AppSignatureHelper.dart';
import 'otp_screen_provider.dart';

class OtpScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
      context.read<OtpScreenProvider>().startTimer();
      _initSmsListener();

      // Get and display app signature
      AppSignatureHelper.getAppSignature();
    });
  }

  @override
  void dispose() {
    cancel(); // Cancel SMS listener
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void codeUpdated() {
    // This callback is triggered when SMS is received
    if (code != null && code!.length == 6) {
      print('Auto-filled OTP: $code');
      _setOtpToControllers(code!);
      _syncOtpToProvider();

      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _verifyOtp();
        }
      });
    }
  }

  /// Initialize SMS auto-fill listener
  Future<void> _initSmsListener() async {
    try {
      // Listen for SMS with proper error handling
      await SmsAutoFill().listenForCode;
      print('✓ SMS listener started successfully');
    } catch (e) {
      print('✗ Error starting SMS listener: $e');
    }
  }

  String _getOtpFromControllers() {
    return _controllers.map((c) => c.text).join();
  }

  void _setOtpToControllers(String otp) {
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = i < otp.length ? otp[i] : '';
    }
  }

  void _syncOtpToProvider() {
    context.read<OtpScreenProvider>().setOtp(_getOtpFromControllers());
  }

  Widget _buildOtpField(BuildContext context, int index) {
    return Container(
      width: 45.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyle.robotoBold.copyWith(
          fontSize: 24.sp,
          color: Colors.black,
          height: 1.0,
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
          isDense: true,
        ),
        textAlignVertical: TextAlignVertical.center,
        onChanged: (value) {
          if (value.length > 1) {
            final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (clean.isNotEmpty) {
              final otp = clean.length > 6 ? clean.substring(0, 6) : clean;
              _setOtpToControllers(otp);
              _syncOtpToProvider();
              if (otp.length == 6) {
                _focusNodes[5].unfocus();
              }
            }
            return;
          }

          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          _syncOtpToProvider();
        },
        onSubmitted: (value) {
          if (index == 5) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  // ============================================================
  // UPDATED METHOD WITH REFERRAL CHECK
  // ============================================================
  Future<void> _verifyOtp() async {
    final provider = context.read<OtpScreenProvider>();
    final otp = _getOtpFromControllers();
    final mobile = widget.phoneNumber;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6 digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('=== Starting OTP verification ===');
    print('Mobile: $mobile');

    if (mobile == null || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await provider.verifyOtp(
      mobile: mobile,
      otp: otp,
      context: context,
    );

    if (result != null && mounted) {
      // FIRST PRIORITY: Check if referral code is needed
      if (result['needsReferralCode'] == true) {
        print('Referral code needed, navigating to ReferralCodeScreen');

        // Setup notifications before navigating
        await _setupNotifications();

        // Navigate to ReferralCodeScreen
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/ReferralCodeScreen",
          (route) => false,
        );
        return;
      }

      // SECOND PRIORITY: Check if email verification is needed
      if (result['needsEmailVerification'] == true) {
        print(
          'Email verification needed, navigating to email verification screen',
        );
        await _setupNotificationsAndNavigate();
      } else {
        // Both referral and email are complete
        print('All verifications complete, navigating to home');
        await _setupNotificationsAndNavigate();
      }
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setupNotifications() async {
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
  }

  // ============================================================
  // EXISTING METHOD: Setup notifications and navigate to home
  // ============================================================
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                        "Enter OTP",
                        style: AppTextStyle.robotoBold.copyWith(
                          fontSize: 28.sp,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        "A 6 digit code has been sent to",
                        style: AppTextStyle.robotoRegular.copyWith(
                          fontSize: 15.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        widget.phoneNumber ?? '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // OTP fields with auto-fill support
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (index) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            child: _buildOtpField(context, index),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Consumer<OtpScreenProvider>(
                        builder: (context, provider, _) {
                          if (provider.errorMessage != null) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        provider.errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      SizedBox(height: 24.h),

                      Consumer<OtpScreenProvider>(
                        builder: (context, provider, _) => SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed:
                                (provider.isLoading ||
                                    provider.isUpdatingDeviceToken)
                                ? null
                                : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.appColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              elevation: 0,
                            ),
                            child:
                                (provider.isLoading ||
                                    provider.isUpdatingDeviceToken)
                                ? SizedBox(
                                    height: 24.h,
                                    width: 24.w,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Verify OTP",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Consumer<OtpScreenProvider>(
                        builder: (context, provider, _) => TextButton(
                          onPressed: provider.canResend
                              ? () => provider.resendOtp(
                                  mobile: widget.phoneNumber,
                                )
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.canResend
                                    ? "Didn't receive code? "
                                    : "Resend in ",
                                style: AppTextStyle.robotoRegular.copyWith(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                provider.canResend
                                    ? "Resend"
                                    : "${provider.secondsRemaining}s",
                                style: AppTextStyle.robotoBold.copyWith(
                                  fontSize: 14.sp,
                                  color: provider.canResend
                                      ? Colors.black
                                      : Colors.grey.shade700,
                                  decoration: provider.canResend
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
