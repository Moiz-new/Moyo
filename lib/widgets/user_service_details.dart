import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/user_screens/WidgetProviders/ServiceAPI.dart';
import '../screens/user_screens/navigation/SOSEmergencyScreen.dart';
import '../screens/user_screens/navigation/UserChats/UserChatScreen.dart';
import 'CancelServiceDialog.dart';
import 'RatingDialog.dart';

class UserServiceDetails extends StatelessWidget {
  final String? serviceId;
  final String? category;
  final String? subCategory;
  final String? date;
  final String? pin;
  final String? providerPhone;
  final String? dp;
  final String? name;
  final String? rating;
  final String status;
  final String? providerId;

  final String? durationType;
  final String? duration;
  final String? price;
  final String? address;
  final List<String>? particular;
  final VoidCallback? onCompleteService;

  final String? description;
  final bool isProvider;
  final bool userRatingGiven;

  final VoidCallback? onAccept;
  final VoidCallback? onReBid;
  final VoidCallback? onCancel;
  final VoidCallback? onTaskComplete;
  final VoidCallback? onRateService;
  final VoidCallback? onSeeWorktime;

  const UserServiceDetails({
    super.key,
    this.serviceId,
    this.category,
    this.subCategory,
    this.date,
    this.pin,
    this.providerPhone,
    this.userRatingGiven = false,
    this.dp,
    this.name,
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
    this.providerId,
    this.onSeeWorktime,
    this.onCompleteService,
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
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController(
      text: "cash",
    );

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Re-Bid Service',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your new bid amount and note',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              SizedBox(height: 16),
              // Amount TextField
              Text(
                'Amount *',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  hintStyle: GoogleFonts.roboto(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorConstant.moyoOrange,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Color(0xFF1D1B20),
                ),
              ),
              SizedBox(height: 16),
              // Note TextField
              Text(
                'Note',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter note...',
                  hintStyle: GoogleFonts.roboto(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorConstant.moyoOrange,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.roboto(
                  fontSize: 14,
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = amountController.text.trim();
                final note = noteController.text.trim();

                if (amount.isEmpty) {
                  _showErrorSnackbar(context, 'Please enter amount');
                  return;
                }

                // Validate amount is numeric
                if (double.tryParse(amount) == null) {
                  _showErrorSnackbar(context, 'Please enter valid amount');
                  return;
                }

                if (note.isEmpty) {
                  _showErrorSnackbar(context, 'Please enter a note');
                  return;
                }

                Navigator.of(context).pop({'amount': amount, 'note': note});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFCD3232),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Re-Bid',
                style: GoogleFonts.roboto(
                  fontSize: 16,
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

  Widget _completeService(BuildContext context) {
    return InkWell(
      onTap: onCompleteService,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
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
            Icon(Icons.check_circle, color: Colors.white, size: 15),
            Text(
              "Complete",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  // Add this method to handle Accept button click
  Future<void> _handleAcceptService(BuildContext context) async {
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
    final statusLower = status.toLowerCase();
    print(statusLower);
    print("ratinggggg$userRatingGiven");
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

            // Accept/ReBid buttons - show for 'open' and 'pending' if provider
            if ((statusLower == "open" || statusLower == "pending") &&
                isProvider)
              _acceptReBid(context),

            // Cancel button - show for 'assigned' status (user side)
            if (statusLower == "assigned" || statusLower == "arrived")
              _cancelTheService(context),

            if (statusLower == "started") _taskComplete(context),

            // Rate service - show for 'completed' status
            if (statusLower == "completed" && !userRatingGiven)
              _rateService(context),
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
              onTap: () => _handleAcceptService(context),
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
              onTap: () => _handleReBidService(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Color(0xFFCD3232),
                  borderRadius: BorderRadius.circular(12.r),
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

  Future<void> _handleReBidService(BuildContext context) async {
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
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Submitting re-bid...',
                  style: GoogleFonts.roboto(
                    fontSize: 16.h,
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

  // Keep all other existing methods unchanged...
  // (Copy all the other methods from your original code)

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

  // Replace the _sosPinTimeLeftCallMessage method with this updated version

  Widget _sosPinTimeLeftCallMessage(
    BuildContext context,
    String? pin,
    String? providerPhone,
  ) {
    final statusLower = status.toLowerCase();

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
                      SOSEmergencyScreen(serviceId: serviceId),
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
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _buildCenterContent(context, pin),
            ),
          ),

          // Call and Message buttons - Hide for pending status
          if (statusLower != "open")
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                // Call Button
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
                      _showErrorSnackbar(context, 'Phone number not available');
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: SvgPicture.asset("assets/icons/moyo_call_action.svg"),
                ),

                // Message/Chat Button
                InkWell(
                  onTap: () {
                    // Navigate to chat screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChatScreen(
                          userName: name ?? "Provider",
                          userImage: dp,
                          serviceId: serviceId,
                          providerId: providerId,
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
  }

  Widget _buildCenterContent(BuildContext context, String? pin) {
    final statusLower = status.toLowerCase();

    // Show PIN for assigned, arrived statuses
    if (statusLower == "assigned" ||
        statusLower == "arrived" ||
        statusLower == "in_progress" ||
        statusLower == "confirmed") {
      return Column(
        children: [
          Text(
            "PIN - ${pin ?? "No Pin"}",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              color: Color(0xFF000000),
            ),
          ),
          if (statusLower == "in_progress") _completeService(context),
        ],
      );
    }

    // Default - empty space
    return SizedBox.shrink();
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

  Future<void> _handleCancelService(BuildContext context) async {
    // Validate required fields with null checks
    if (serviceId == null || serviceId!.isEmpty) {
      _showErrorSnackbar(context, 'Service ID is missing');
      return;
    }

    try {
      // Show cancellation bottom sheet
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return CancelServiceBottomSheet(serviceId: serviceId!);
        },
      );

      // If cancellation was successful
      if (result == true && context.mounted) {
        _showSuccessSnackbar(context, 'Service cancelled successfully');

        // Add delay to show snackbar, then pop
        await Future.delayed(Duration(milliseconds: 500));

        // Pop the screen to go back
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Call the original onCancel callback if provided
        if (onCancel != null) {
          onCancel!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _cancelTheService(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _handleCancelService(context),
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

  Future<void> _handleRateService(BuildContext context) async {
    // Validate required data with null checks
    if (serviceId == null || serviceId!.isEmpty) {
      _showErrorSnackbar(context, 'Service ID is missing');
      return;
    }

    // Use the providerId from the widget's field
    if (providerId == null || providerId!.isEmpty) {
      _showErrorSnackbar(context, 'Provider information is missing');
      return;
    }

    try {
      // Show rating dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RatingDialog(
            serviceId: serviceId!,
            providerId: providerId!,
            providerName: name,
          );
        },
      );

      // If rating was submitted successfully
      if (result == true && context.mounted) {
        _showSuccessSnackbar(context, 'Thank you for rating the service!');

        // Add delay to show snackbar, then pop
        await Future.delayed(Duration(milliseconds: 500));

        // Pop the screen to go back
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Call the original onRateService callback if provided
        if (onRateService != null) {
          onRateService!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // Update the _rateService widget to use the new handler
  Widget _rateService(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _handleRateService(context),
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
