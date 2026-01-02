// lib/screens/referral/referral_code_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/colorConstant/color_constant.dart';
import 'ReferralBloc.dart';
import 'ReferralEvent.dart';
import 'ReferralRepository.dart';
import 'ReferralState.dart';

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({Key? key}) : super(key: key);

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  final TextEditingController _referralController = TextEditingController();

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // BLoC ko provide karein
      create: (context) => ReferralBloc(repository: ReferralRepository()),
      child: Scaffold(
        backgroundColor: ColorConstant.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: BlocConsumer<ReferralBloc, ReferralState>(
            // State changes ko listen karein
            listener: (context, state) {
              if (state is ReferralSuccess) {
                // Success message show karein
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ColorConstant.moyoGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );

                // Success ke baad next screen par navigate karein
                // 2 seconds delay ke baad navigate karein
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) {
                    print('=== Navigating to home screen ===');
                    print('Referral Data: ${state.referralData?.referralCode}');
                    print('Reward Amount: ${state.referralData?.rewardAmount}');

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/UserCustomBottomNav",
                      (route) => false,
                    );
                  }
                });
              } else if (state is ReferralError) {
                // Error message show karein
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is ReferralSkipped) {
                // Skip ke baad immediately next screen par navigate karein
                if (mounted) {
                  print(
                    '=== Skipped referral code - Navigating to home screen ===',
                  );

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/UserCustomBottomNav",
                    (route) => false,
                  );
                }
              }
            },
            // UI build karein based on state
            builder: (context, state) {
              final isLoading = state is ReferralLoading;

              return SingleChildScrollView(
                physics: ClampingScrollPhysics(),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 40.h),

                          // Logo with subtle shadow
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: ColorConstant.moyoOrange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 80.w,
                              height: 80.h,
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Title
                          Text(
                            'Enter Referral Code',
                            style: TextStyle(
                              color: ColorConstant.onSurface,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // Description
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              'Have a referral code? Enter it below to unlock exclusive benefits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ColorConstant.onSurface.withOpacity(0.6),
                                fontSize: 14.sp,
                                height: 1.5,
                              ),
                            ),
                          ),

                          SizedBox(height: 40.h),

                          // Referral Code Input
                          Container(
                            decoration: BoxDecoration(
                              color: ColorConstant.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: ColorConstant.moyoOrange.withOpacity(
                                  0.5,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstant.moyoOrange.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _referralController,
                              textAlign: TextAlign.center,
                              enabled: !isLoading,
                              // Loading ke time disable karein
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: ColorConstant.moyoOrange,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'ENTER CODE',
                                hintStyle: TextStyle(
                                  color: ColorConstant.onSurface.withOpacity(
                                    0.25,
                                  ),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 20.h,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 56.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorConstant.moyoOrange,
                                  ColorConstant.moyoOrange.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstant.moyoOrange.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      // Validation
                                      final code = _referralController.text
                                          .trim();

                                      if (code.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please enter a referral code',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      context.read<ReferralBloc>().add(
                                        ApplyReferralCodeEvent(code),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: ColorConstant.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      height: 24.h,
                                      width: 24.w,
                                      child: CircularProgressIndicator(
                                        color: ColorConstant.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Apply Code',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Skip Button
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    // BLoC ko skip event send karein
                                    context.read<ReferralBloc>().add(
                                      SkipReferralEvent(),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: ColorConstant.onSurface.withOpacity(0.5),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // Benefits Section
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: ColorConstant.scaffoldGray,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard_rounded,
                                      color: ColorConstant.moyoOrange,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'Get exclusive rewards',
                                        style: TextStyle(
                                          color: ColorConstant.onSurface
                                              .withOpacity(0.7),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      color: ColorConstant.moyoOrange,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'Unlock special features',
                                        style: TextStyle(
                                          color: ColorConstant.onSurface
                                              .withOpacity(0.7),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
