import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CancelServiceResponse {
  final bool success;
  final String? message;
  final dynamic data;

  CancelServiceResponse({required this.success, this.message, this.data});

  factory CancelServiceResponse.fromJson(Map<String, dynamic> json) {
    return CancelServiceResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}

class CancelServiceAPI {
  static Future<CancelServiceResponse> cancelService({
    required String serviceId,
    required String reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      if (serviceId.isEmpty) {
        throw Exception('Service ID is required');
      }

      if (reason.isEmpty) {
        throw Exception('Cancellation reason is required');
      }

      final url = Uri.parse('$base_url/bid/api/service/cancel-service');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'service_id': serviceId, 'reason': reason}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Cancel Service Response Status: ${response.statusCode}');
      print('Cancel Service Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return CancelServiceResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Service not found or already cancelled.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to cancel service. Please try again.',
        );
      }
    } catch (e) {
      print('Error cancelling service: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}

// Dialog Widget

class CancelServiceDialog extends StatefulWidget {
  final String serviceId;

  const CancelServiceDialog({Key? key, required this.serviceId})
      : super(key: key);

  @override
  State<CancelServiceDialog> createState() => _CancelServiceDialogState();
}

class _CancelServiceDialogState extends State<CancelServiceDialog> {
  String? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> cancellationReasons = [
    'Personal emergency',
    'Customer unresponsive / unable to confirm',
    'Customer requested cancellation directly',
    'Incorrect service details provided by customer',
    'Pricing issue',
    'Other (please specify)',
  ];

  bool isLoading = false;

  @override
  void dispose() {
    otherReasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleCancellation() async {
    if (selectedReason == null || selectedReason!.isEmpty) {
      _showErrorSnackbar('Please select a cancellation reason');
      return;
    }

    if (selectedReason == 'Other (please specify)') {
      final otherReason = otherReasonController.text.trim();
      if (otherReason.isEmpty) {
        _showErrorSnackbar('Please specify the reason');
        return;
      }
      if (otherReason.length < 10) {
        _showErrorSnackbar(
          'Please provide more details (at least 10 characters)',
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String finalReason = selectedReason == 'Other (please specify)'
          ? otherReasonController.text.trim()
          : selectedReason!;

      final response = await CancelServiceAPI.cancelService(
        serviceId: widget.serviceId,
        reason: finalReason,
      );

      setState(() {
        isLoading = false;
      });

      if (response.success) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showErrorSnackbar(
          response.message ?? 'Failed to cancel service. Please try again.',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFC4242E),
                    size: 28,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Cancel Service',
                      style: GoogleFonts.roboto(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close, color: Color(0xFF7A7A7A)),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please select a reason for cancellation:',
                      style: GoogleFonts.roboto(
                        fontSize: 14.sp,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Radio buttons
                    ...cancellationReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(
                          reason,
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: Color(0xFFC4242E),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: isLoading
                            ? null
                            : (value) {
                          setState(() {
                            selectedReason = value;
                          });
                          if (value == 'Other (please specify)') {
                            _scrollToBottom();
                          }
                        },
                      );
                    }).toList(),

                    // Text field for "Other"
                    if (selectedReason == 'Other (please specify)') ...[
                      SizedBox(height: 12.h),
                      TextField(
                        controller: otherReasonController,
                        maxLines: 3,
                        maxLength: 200,
                        enabled: !isLoading,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Please specify the reason...',
                          hintStyle:
                          GoogleFonts.roboto(color: Color(0xFFBDBDBD)),
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
                              color: Color(0xFFC4242E),
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
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFE6E6E6), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        side: BorderSide(
                          color: isLoading
                              ? Color(0xFFE6E6E6)
                              : Color(0xFF7A7A7A),
                        ),
                      ),
                      child: Text(
                        'Keep Service',
                        style: GoogleFonts.roboto(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isLoading
                              ? Color(0xFFBDBDBD)
                              : Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleCancellation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC4242E),
                        disabledBackgroundColor: Color(0xFFE6E6E6),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        'Cancel Service',
                        style: GoogleFonts.roboto(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
  }
}