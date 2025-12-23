import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingResponse {
  final bool success;
  final String? message;
  final dynamic data;

  RatingResponse({required this.success, this.message, this.data});

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: json['data'],
    );
  }
}

class RatingAPI {
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('provider_auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  static Future<RatingResponse> submitRating({
    required String serviceId,
    required int rating,
    required String review,
    required String providerId,
  }) async {
    try {
      // Validate inputs
      if (serviceId.isEmpty) {
        throw Exception('Service ID is required');
      }

      if (providerId.isEmpty) {
        throw Exception('Provider ID is required');
      }

      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      if (review.trim().isEmpty) {
        throw Exception('Review is required');
      }

      // Get auth token
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Prepare request body with exact field names and types
      final requestBody = {
        'service_id': serviceId,
        'rating': rating,
        'review': review.trim(),
        'rated_to_user_id': providerId.toString(),
      };

      print('📤 Submitting rating to: $base_url/bid/api/user/rating/create');
      print('📤 Request body: ${jsonEncode(requestBody)}');
      print('📤 Token: ${token.substring(0, 20)}...');

      // Make API request
      final response = await http
          .post(
            Uri.parse('$base_url/bid/api/user/rating/create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout. Please check your connection.');
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            if (data.containsKey('success')) {
              return RatingResponse.fromJson(data);
            }
            return RatingResponse(
              success: true,
              message:
                  data['message']?.toString() ??
                  'Rating submitted successfully',
              data: data['data'],
            );
          }

          return RatingResponse(
            success: true,
            message: 'Rating submitted successfully',
            data: data,
          );
        } catch (e) {
          print('Error parsing response: $e');
          return RatingResponse(
            success: true,
            message: 'Rating submitted successfully',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(
            data['message'] ?? data['error'] ?? 'Invalid request',
          );
        } catch (e) {
          throw Exception('Invalid request. Please check your input.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Service or provider not found');
      } else if (response.statusCode == 500) {
        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['error'] ?? data['message'] ?? 'Server error';
          print('❌ Server error details: $errorMsg');
          throw Exception('Server error: $errorMsg. Please try again later.');
        } catch (e) {
          throw Exception(
            'Server error. Please contact support if this persists.',
          );
        }
      } else {
        throw Exception(
          'Failed to submit rating (${response.statusCode}). Please try again.',
        );
      }
    } catch (e) {
      print('❌ Error submitting rating: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}

// Rating Dialog Widget with ScreenUtilInit

class ProviderRatingDialog extends StatefulWidget {
  final String? serviceId;
  final String? userId;
  final String? providerName;

  const ProviderRatingDialog({
    Key? key,
    this.serviceId,
    this.userId,
    this.providerName,
  }) : super(key: key);

  @override
  State<ProviderRatingDialog> createState() => _ProviderRatingDialogState();
}

class _ProviderRatingDialogState extends State<ProviderRatingDialog> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    // Validate rating
    if (_rating == 0) {
      _showError('Please select a rating');
      return;
    }

    // Validate review
    final review = _reviewController.text.trim();
    if (review.isEmpty) {
      _showError('Please enter a review');
      return;
    }

    if (review.length < 5) {
      _showError('Review should be at least 5 characters');
      return;
    }

    // Validate required data
    if (widget.serviceId == null || widget.serviceId!.isEmpty) {
      _showError('Service ID is missing');
      return;
    }

    if (widget.userId == null || widget.userId!.isEmpty) {
      _showError('Provider ID is missing');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🎯 Submitting rating:');
      print('   Service ID: ${widget.serviceId}');
      print('   Provider ID: ${widget.userId}');
      print('   Rating: $_rating');
      print('   Review: $review');

      final response = await RatingAPI.submitRating(
        serviceId: widget.serviceId!,
        rating: _rating,
        review: review,
        providerId: widget.userId!,
      );

      if (response.success) {
        if (mounted) {
          Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
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
                                  });
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

                  SizedBox(height: 12.h),

                  // Review TextField
                  Text(
                    'Write your review *',
                    style: GoogleFonts.roboto(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _reviewController,
                    enabled: !_isSubmitting,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: GoogleFonts.roboto(
                        color: Color(0xFFBDBDBD),
                        fontSize: 13.sp,
                      ),
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
                          color: Color(0xFFFFA726),
                          width: 1.5.w,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(10.w),
                      counterStyle: GoogleFonts.roboto(fontSize: 11.sp),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 13.sp,
                      color: Color(0xFF1D1B20),
                    ),
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
    );
  }
}
