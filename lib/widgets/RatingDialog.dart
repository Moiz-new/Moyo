import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'RatingReasonsProvider.dart';

class RatingDialog extends StatefulWidget {
  final String? serviceId;
  final String? providerId;
  final String? providerName;

  const RatingDialog({
    Key? key,
    this.serviceId,
    this.providerId,
    this.providerName,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RatingReasonsProvider>().reset();
    });
  }

  /// Submit rating to API
  Future<void> _submitRating() async {
    if (_rating == 0) {
      _showError('Please select a rating');
      return;
    }

    if (_selectedReason == null || _selectedReason!.isEmpty) {
      _showError('Please select a reason');
      return;
    }

    if (widget.serviceId == null || widget.serviceId!.isEmpty) {
      _showError('Service ID is missing');
      return;
    }

    if (widget.providerId == null || widget.providerId!.isEmpty) {
      _showError('Provider ID is missing');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🎯 Submitting rating:');
      print('   Service ID: ${widget.serviceId}');
      print('   Provider ID: ${widget.providerId}');
      print('   Rating: $_rating');
      print('   Reason: $_selectedReason');

      final response = await RatingAPI.submitRating(
        serviceId: widget.serviceId!,
        rating: _rating,
        review: _selectedReason!,
        providerId: widget.providerId!,
      );

      if (response.success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          _showSuccess('Rating submitted successfully');
        }
      } else {
        _showError(response.message ?? 'Failed to submit rating');
      }
    } catch (e) {
      print('❌ Dialog error: $e');
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Show error snackbar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFC4242E),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RatingReasonsProvider(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            title: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                'Rate Service',
                style: GoogleFonts.roboto(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(maxWidth: 400.w),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Name
                    if (widget.providerName != null &&
                        widget.providerName!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Rate ${widget.providerName}',
                          style: GoogleFonts.roboto(
                            fontSize: 13.sp,
                            color: Color(0xFF7A7A7A),
                          ),
                        ),
                      ),

                    // Star Rating
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.all(4.w),
                            constraints: BoxConstraints(),
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _rating = index + 1;
                                      _selectedReason = null;
                                    });
                                    // Fetch reasons for selected rating
                                    context
                                        .read<RatingReasonsProvider>()
                                        .fetchRatingReasons(_rating);
                                  },
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: index < _rating
                                  ? Color(0xFFFFA726)
                                  : Color(0xFFBDBDBD),
                              size: 32.sp,
                            ),
                          );
                        }),
                      ),
                    ),

                    // Rating Label
                    if (_rating > 0)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            _rating == 1
                                ? 'Poor'
                                : _rating == 2
                                ? 'Fair'
                                : _rating == 3
                                ? 'Good'
                                : _rating == 4
                                ? 'Very Good'
                                : 'Excellent',
                            style: GoogleFonts.roboto(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 16.h),

                    // Rating Reasons Section
                    if (_rating > 0)
                      Consumer<RatingReasonsProvider>(
                        builder: (context, provider, child) {
                          // Loading state
                          if (provider.isLoading) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFA726),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          // Error state
                          if (provider.error != null) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFC4242E),
                                      size: 32.sp,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Failed to load reasons',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12.sp,
                                        color: Color(0xFF7A7A7A),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    TextButton(
                                      onPressed: () {
                                        provider.fetchRatingReasons(_rating);
                                      },
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12.sp,
                                          color: Color(0xFFFFA726),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Empty state
                          if (provider.reasons.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: Text(
                                  'No reasons available',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12.sp,
                                    color: Color(0xFF7A7A7A),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Reasons list
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select a reason *',
                                style: GoogleFonts.roboto(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D1B20),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              ...provider.reasons.map((reason) {
                                final isSelected =
                                    _selectedReason == reason.reason;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: InkWell(
                                    onTap: _isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedReason = reason.reason;
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 12.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Color(0xFFFFF3E0)
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? Color(0xFFFFA726)
                                              : Color(0xFFE6E6E6),
                                          width: isSelected ? 1.5.w : 1.w,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? Color(0xFFFFA726)
                                                : Color(0xFFBDBDBD),
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text(
                                              reason.reason,
                                              style: GoogleFonts.roboto(
                                                fontSize: 13.sp,
                                                color: Color(0xFF1D1B20),
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),

                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: _isSubmitting
                              ? Color(0xFFBDBDBD)
                              : Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA726),
                        disabledBackgroundColor: Color(0xFFBDBDBD),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
