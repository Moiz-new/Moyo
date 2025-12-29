import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/EditProviderProfileScreen.dart';
import 'package:first_flutter/screens/user_screens/Profile/EditProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../baseControllers/APis.dart';

import '../screens/provider_screens/navigation/ProviderChats/ProviderChatScreen.dart';
import '../screens/user_screens/WidgetProviders/ServiceAPI.dart';
import '../screens/provider_screens/ServiceArrivalProvider.dart';
import '../screens/user_screens/navigation/ProviderSOSEmergencyScreen.dart';
import '../screens/user_screens/navigation/SOSEmergencyScreen.dart';

class ProviderConfirmServiceDetails extends StatelessWidget {
  final String? serviceId;
  final String? category;
  final String? subCategory;
  final String? date;
  final String? pin;
  final String? providerPhone;
  final String? dp;
  final String? name;
  final String? budget;
  final String? rating;
  final String status;
  final VoidCallback? onStartWork;
  final VoidCallback? onSeeWorktime;
  final VoidCallback? onRating;

  final String? durationType;
  final String? duration;
  final String? price;
  final String? address;
  final List<String>? particular;

  final String? description;
  final bool isProvider;
  String? user_id;

  final VoidCallback? onAccept;
  final VoidCallback? onReBid;
  final VoidCallback? onCancel;
  final VoidCallback? onTaskComplete;
  final VoidCallback? onRateService;

  ProviderConfirmServiceDetails({
    super.key,
    this.serviceId,
    this.category,
    this.subCategory,
    this.date,
    this.pin,
    this.providerPhone,
    this.dp,
    this.name,
    this.budget,
    this.rating,
    this.status = "No status",
    this.durationType,
    this.duration,
    this.price,
    this.address,
    this.particular,
    this.description,
    this.isProvider = false,
    this.onAccept,
    this.onReBid,
    this.onCancel,
    this.onTaskComplete,
    this.onRateService,
    this.onStartWork,
    this.onSeeWorktime,
    this.user_id,
    this.onRating,
  });

  // Add this method to show note popup
  Future<String?> _showNoteDialog(BuildContext context) async {
    final TextEditingController noteController = TextEditingController(
      text: "cash",
    );

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Add Note',
            style: GoogleFonts.roboto(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please add a note for this service (e.g., payment method)',
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter note...',
                  hintStyle: GoogleFonts.roboto(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: ColorConstant.moyoOrange,
                      width: 2.w,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(12.w),
                ),
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  _showErrorSnackbar(context, 'Please enter a note');
                  return;
                }
                Navigator.of(context).pop(note);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoGreen,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>?> _showReBidDialog(BuildContext context) async {
    final TextEditingController amountController = TextEditingController(
      text: price,
    );
    double baseAmount = double.tryParse(price!) ?? 0;

    final TextEditingController noteController = TextEditingController(
      text: "cash",
    );
    String? amountError;

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void validateAmount() {
              if (amountController.text.isEmpty) {
                setState(() => amountError = null);
                return;
              }

              double entered = double.tryParse(amountController.text) ?? 0;
              double minAllowed = baseAmount * 0.70;
              double maxAllowed = baseAmount * 2.00;

              setState(() {
                if (entered < minAllowed) {
                  amountError =
                      "Amount must be at least ₹${minAllowed.toStringAsFixed(2)}";
                } else if (entered > maxAllowed) {
                  amountError =
                      "Amount must not exceed ₹${maxAllowed.toStringAsFixed(2)}";
                } else {
                  amountError = null;
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 24.h,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Text(
                        'Re-Bid Service',
                        style: GoogleFonts.roboto(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter your new bid amount and note',
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Amount *',
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => validateAmount(),
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                prefixText: '₹ ',
                                errorText: amountError,
                                hintStyle: GoogleFonts.roboto(
                                  color: Color(0xFFBDBDBD),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Color(0xFFE6E6E6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Color(0xFFE6E6E6),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: ColorConstant.moyoOrange,
                                    width: 2.w,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.all(12.w),
                              ),
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Note',
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: noteController,
                              maxLines: 3,
                              maxLength: 200,
                              decoration: InputDecoration(
                                hintText: 'Enter note...',
                                hintStyle: GoogleFonts.roboto(
                                  color: Color(0xFFBDBDBD),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Color(0xFFE6E6E6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Color(0xFFE6E6E6),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: ColorConstant.moyoOrange,
                                    width: 2.w,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.all(12.w),
                              ),
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(null);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.roboto(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          ElevatedButton(
                            onPressed: () {
                              final amount = amountController.text.trim();
                              final note = noteController.text.trim();

                              if (amount.isEmpty) {
                                _showErrorSnackbar(
                                  context,
                                  'Please enter amount',
                                );
                                return;
                              }

                              double entered = double.tryParse(amount) ?? 0;
                              double minAllowed = baseAmount * 0.70;
                              double maxAllowed = baseAmount * 2.00;

                              if (entered < minAllowed) {
                                _showErrorSnackbar(
                                  context,
                                  "Amount must be at least ₹${minAllowed.toStringAsFixed(2)}",
                                );
                                return;
                              } else if (entered > maxAllowed) {
                                _showErrorSnackbar(
                                  context,
                                  "Amount must not exceed ₹${maxAllowed.toStringAsFixed(2)}",
                                );
                                return;
                              }

                              if (note.isEmpty) {
                                _showErrorSnackbar(
                                  context,
                                  'Please enter a note',
                                );
                                return;
                              }

                              Navigator.of(
                                context,
                              ).pop({'amount': amount, 'note': note});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCD3232),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Submit Re-Bid',
                              style: GoogleFonts.roboto(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _handleAcceptService(BuildContext context) async {
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('$base_url/api/auth/profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("object");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isRegister = data['profile']['provider']['isregistered'] ?? false;
        bool isUserRegister = data['profile']['isregister'] ?? false;

        if (isRegister == false || isUserRegister == false) {
          // Show profile incomplete popup
          final shouldNavigate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: ColorConstant.moyoOrange,
                      size: 28.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Profile Incomplete',
                      style: GoogleFonts.roboto(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Please complete your profile to accept services. You will be redirected to the profile edit screen.',
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Complete Profile',
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          // If user clicked "Complete Profile", navigate to edit profile screen
          if (shouldNavigate == true) {
            // Check which profile is incomplete and navigate accordingly
            if (isRegister == false) {
              // Provider profile is incomplete
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProviderProfileScreen(),
                ),
              );
            } else if (isUserRegister == false) {
              // User profile is incomplete
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to verify profile status');
      return;
    }

    // Validate required fields
    if (serviceId == null || serviceId!.isEmpty) {
      _showErrorSnackbar(context, 'Service ID is missing');
      return;
    }

    if (price == null || price!.isEmpty) {
      _showErrorSnackbar(context, 'Price is missing');
      return;
    }

    // Show note dialog first
    final note = await _showNoteDialog(context);

    // If user cancelled the dialog, return
    if (note == null) {
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Accepting service...',
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Call the API with the note from dialog
      final response = await ServiceAPI.acceptService(
        serviceId: serviceId!,
        amount: price!,
        notes: note,
        status: "pending",
      );

      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.success) {
        // Show success message
        if (context.mounted) {
          _showSuccessSnackbar(
            context,
            response.message ?? 'Service accepted successfully',
          );

          // Add delay to show snackbar, then pop
          await Future.delayed(Duration(milliseconds: 500));

          // Pop the screen to go back
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }

        // Call the original onAccept callback if provided
        if (onAccept != null) {
          onAccept!();
        }
      } else {
        // Show error message
        if (context.mounted) {
          _showErrorSnackbar(
            context,
            response.message ?? 'Failed to accept service',
          );
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        _showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleReBidService(BuildContext context) async {
    // First check profile completion status
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('$base_url/api/auth/profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isRegister = data['profile']['provider']['isregistered'] ?? false;
        bool isUserRegister = data['profile']['isregister'] ?? false;

        if (isRegister == false || isUserRegister == false) {
          // Show profile incomplete popup
          final shouldNavigate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: ColorConstant.moyoOrange,
                      size: 28.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Profile Incomplete',
                      style: GoogleFonts.roboto(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Please complete your profile to re-bid on services. You will be redirected to the profile edit screen.',
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Complete Profile',
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          // If user clicked "Complete Profile", navigate to edit profile screen
          if (shouldNavigate == true) {
            // Check which profile is incomplete and navigate accordingly
            if (isRegister == false) {
              // Provider profile is incomplete
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProviderProfileScreen(),
                ),
              );
            } else if (isUserRegister == false) {
              // User profile is incomplete
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to verify profile status');
      return;
    }

    // Validate required fields
    if (serviceId == null || serviceId!.isEmpty) {
      _showErrorSnackbar(context, 'Service ID is missing');
      return;
    }

    // Show rebid dialog to get amount and note
    final result = await _showReBidDialog(context);

    // If user cancelled the dialog, return
    if (result == null) {
      return;
    }

    final newAmount = result['amount']!;
    final note = result['note']!;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Submitting re-bid...',
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Call the same API with new amount
      final response = await ServiceAPI.acceptService(
        serviceId: serviceId!,
        amount: newAmount,
        notes: note,
        status: "Rebid",
      );

      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.success) {
        // Show success message
        if (context.mounted) {
          _showSuccessSnackbar(
            context,
            response.message ?? 'Re-bid submitted successfully',
          );

          // Add delay to show snackbar, then pop
          await Future.delayed(Duration(milliseconds: 500));

          // Pop the screen to go back
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }

        // Call the original onReBid callback if provided
        if (onReBid != null) {
          onReBid!();
        }
      } else {
        // Show error message
        if (context.mounted) {
          _showErrorSnackbar(
            context,
            response.message ?? 'Failed to submit re-bid',
          );
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        _showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ColorConstant.moyoGreen,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFC4242E),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Current status: $status");
    print("isprovider: $isProvider");
    print("serviceId: $serviceId");

    final statusLower = status.toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Container(
        padding: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          spacing: 10,
          children: [
            _catSubCatDate(context, category, subCategory, date),

            // Hide SOS section for completed and cancelled
            if (!(statusLower == "completed" || statusLower == "cancelled"))
              _sosPinTimeLeftCallMessage(context, pin, providerPhone),

            _dpNameStatus(context, _currentStatusChip(context, status)),

            _durationTypeDurationAndPrice(
              context,
              durationType,
              duration,
              price,
            ),

            _userAddress(context, address),

            if (particular != null) _particular(context, particular!),

            _description(context, description),

            Consumer<ServiceArrivalProvider>(
              builder: (context, arrivalProvider, child) {
                return _buildCenterContent(context, arrivalProvider);
              },
            ),

            // Accept/ReBid buttons - show for 'open' and 'pending' if provider
            if ((statusLower == "open" || statusLower == "pending") &&
                isProvider)
              _acceptReBid(context),

            // Cancel button - show for 'assigned' status
            /*   if (statusLower == "assigned" || statusLower == "arrived")
              _cancelTheService(context),*/

            // Task complete - show for 'started' or 'in_progress' status
            if (statusLower == "started" || statusLower == "in_progress")
              _taskComplete(context),

            // Rate service - show for 'completed' status
            //if (statusLower == "completed") _rateService(context),
          ],
        ),
      ),
    );
  }

  // Update _acceptReBid to use the new API handler
  Widget _acceptReBid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                print("Accept button tapped");
                _handleAcceptService(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ColorConstant.moyoGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      "Accept",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                print("ReBid button tapped");
                _handleReBidService(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFCD3232),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      "Re Bid",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w500,
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
    );
  }

  Widget _currentStatusChip(BuildContext context, String? status3) {
    final statusLower = status3?.toLowerCase() ?? '';

    switch (statusLower) {
      case 'open':
        return _buildStatusChip(
          context,
          text: "Open",
          backgroundColor: Color(0xFFE8F5E9),
          textColor: ColorConstant.moyoGreen,
        );

      case 'pending':
        return _buildStatusChip(
          context,
          text: "Pending",
          backgroundColor: Color(0xFFFFF3E0),
          textColor: Color(0xFFF57C00),
        );

      case 'assigned':
        return _buildStatusChip(
          context,
          text: "Assigned",
          backgroundColor: Color(0xFFDEEAFA),
          textColor: Color(0xFF1A4E88),
        );

      case 'started':
        return _buildStatusChip(
          context,
          text: "Started",
          backgroundColor: Color(0xFFE1F5FE),
          textColor: Color(0xFF0277BD),
        );

      case 'arrived':
        return _buildStatusChip(
          context,
          text: "Arrived",
          backgroundColor: Color(0xFFE8EAF6),
          textColor: Color(0xFF3F51B5),
        );

      case 'in_progress':
        return _buildStatusChip(
          context,
          text: "In Progress",
          backgroundColor: Color(0xFFFFF9C4),
          textColor: Color(0xFFF57F17),
        );

      case 'completed':
        return _buildStatusChip(
          context,
          text: "Completed",
          backgroundColor: Color(0xFFE6F7C0),
          textColor: ColorConstant.moyoGreen,
        );

      case 'cancelled':
        return _buildStatusChip(
          context,
          text: "Cancelled",
          backgroundColor: Color(0xFFFEE8E8),
          textColor: Color(0xFFDB4A4C),
        );

      case 'closed':
        return _buildStatusChip(
          context,
          text: "Closed",
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF616161),
        );

      // Legacy statuses for backward compatibility
      case 'confirmed':
        return _buildStatusChip(
          context,
          text: "Confirmed",
          backgroundColor: Color(0xFFDEEAFA),
          textColor: Color(0xFF1A4E88),
        );

      case 'ongoing':
        return _buildStatusChip(
          context,
          text: "Ongoing",
          backgroundColor: Color(0xFFFFF9C4),
          textColor: Color(0xFFF57F17),
        );

      default:
        return SizedBox(width: 0, height: 0);
    }
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          color: textColor,
        ),
      ),
    );
  }

  Widget _catSubCatDate(
    BuildContext context,
    String? category,
    String? subCategory,
    String? date,
  ) {
    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "$category > $subCategory",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                color: Color(0xFF1D1B20),
              ),
            ),
          ),
          Text(
            date ?? "No date",
            style: GoogleFonts.roboto(
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.black.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosPinTimeLeftCallMessage(
    BuildContext context,
    String? pin,
    String? providerPhone,
  ) {
    return Consumer<ServiceArrivalProvider>(
      builder: (context, arrivalProvider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // SOS Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProviderSOSEmergencyScreen(serviceId: serviceId),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF0000),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Text(
                    "SOS",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      textStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),

              if (status == "arrived" || status == "in_progress")
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: _startWork(context),
                  ),
                ),

              // Right Section - Call and Message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  InkWell(
                    onTap: () async {
                      if (providerPhone != null && providerPhone.isNotEmpty) {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: providerPhone,
                        );

                        try {
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            _showErrorSnackbar(
                              context,
                              'Could not launch dialer',
                            );
                          }
                        } catch (e) {
                          _showErrorSnackbar(
                            context,
                            'Error launching dialer: $e',
                          );
                        }
                      } else {
                        _showErrorSnackbar(
                          context,
                          'Phone number not available',
                        );
                      }
                    },
                    child: SvgPicture.asset(
                      "assets/icons/moyo_call_action.svg",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Navigate to chat screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderChatScreen(
                            userName: name ?? "Provider",
                            userImage: dp,
                            serviceId: serviceId,
                            providerId: user_id,
                            isOnline: true,
                            userPhone: providerPhone,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: SvgPicture.asset(
                      "assets/icons/moyo_message_action.svg",
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(
    BuildContext context,
    ServiceArrivalProvider arrivalProvider,
  ) {
    final statusLower = status.toLowerCase();

    // Show timer if arrived and timer is active
    if (statusLower == "arrived" &&
        isProvider &&
        arrivalProvider.hasArrived &&
        arrivalProvider.isTimerActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.all(Radius.circular(50)),
            border: Border.all(color: Color(0xFF1976D2), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.timer, color: Color(0xFF1976D2), size: 18),
              Text(
                arrivalProvider.formattedTime,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default - empty space
    return SizedBox.shrink();
  }

  String? _timeLeft(
    BuildContext context, {
    String? serviceStartTime,
    String? duration,
  }) {
    return "03 : 29";
  }

  Widget _startWork(BuildContext context) {
    return InkWell(
      onTap: onStartWork,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        decoration: BoxDecoration(
          color: ColorConstant.moyoGreen,
          border: Border.all(color: ColorConstant.moyoGreen, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.work, color: Colors.white, size: 20),
            Text(
              "Start Work",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workTime(BuildContext context) {
    return InkWell(
      onTap: onSeeWorktime,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstant.moyoOrange,
          border: Border.all(color: ColorConstant.moyoGreen, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.timelapse, color: Colors.white, size: 20),
            Text(
              "Work time",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dpNameStatus(context, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        mainAxisSize: MainAxisSize.max,
        children: [
          if ((status != "pending") || isProvider)
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              height: 45,
              width: 45,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: dp ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Image.asset('assets/images/moyo_image_placeholder.png'),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/moyo_image_placeholder.png'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if ((status != "pending") || isProvider)
                      Expanded(
                        child: Text(
                          name ?? "No Name",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            textStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 6,
                        children: [child],
                      ),
                    ),
                  ],
                ),
                if ((status != "pending") || isProvider)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "⭐ ${rating ?? '0.0'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            textStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationTypeDurationAndPrice(
    BuildContext context,
    String? durationType,
    String? duration,
    String? price,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrangeFade,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: Text(
                durationType ?? "No Duration",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  color: ColorConstant.moyoOrange,
                ),
              ),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                SvgPicture.asset(
                  "assets/icons/moyo_material-symbols_timer-outline.svg",
                ),
                Text(
                  duration ?? "No Duration",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    textStyle: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Color(0xFF000000)),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              "₹ ${price ?? "No Price"} /-",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userAddress(BuildContext context, String? address) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Text(
        address ?? "No Address",
        textAlign: TextAlign.start,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Color(0xFF7A7A7A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _particular(BuildContext context, List<String> particular) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          ...particular.map(
            (e) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrangeFade,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: Text(
                e,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _description(BuildContext context, String? description) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Text(
        description ?? "No description",
        textAlign: TextAlign.start,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _cancelTheService(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onCancel,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFFFE3E3),
            border: Border.all(color: Color(0xFFC4242E), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              SvgPicture.asset("assets/icons/moyo_close-filled.svg"),
              Text(
                "Cancel the service",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Color(0xFFFF0000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskComplete(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTaskComplete,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFC4242E),
            border: Border.all(color: Color(0xFFC4242E), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              SvgPicture.asset("assets/icons/moyo_task-complete.svg"),
              Text(
                "Task Complete",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateService(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onRateService,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ColorConstant.moyoOrange,
            border: Border.all(color: ColorConstant.moyoOrange, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              SvgPicture.asset("assets/icons/moyo_white_star.svg"),
              Text(
                "Rate Service",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
