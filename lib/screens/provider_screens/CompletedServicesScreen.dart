import 'dart:convert';

import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colorConstant/color_constant.dart';
import '../../widgets/ProviderRatingDialog.dart';

class CompletedServicesScreen extends StatefulWidget {
  @override
  _CompletedServicesScreenState createState() =>
      _CompletedServicesScreenState();
}

class _CompletedServicesScreenState extends State<CompletedServicesScreen> {
  List<dynamic> services = [];
  bool isLoading = true;
  String? token;
  Set<int> expandedCards = {};

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchServices();
  }

  Future<void> _loadTokenAndFetchServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('provider_auth_token');
      if (token != null) {
        await _fetchCompletedServices();
      }
    } catch (e) {
      print('Error loading token: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCompletedServices() async {
    try {
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$base_url/bid/api/service/provider-service-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Token: $token');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            services = data['services'] ?? [];
          });
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load services'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRatingDialog(dynamic service) async {
    try {
      if (service == null) return;

      final customer = service['customer'];
      if (customer == null) {
        _showErrorSnackBar('Customer information not available');
        return;
      }

      final userId = service['user_id']?.toString();
      final serviceId = service['id']?.toString();

      if (userId == null || userId.isEmpty || serviceId == null || serviceId.isEmpty) {
        _showErrorSnackBar('Unable to rate this service. Missing required information.');
        return;
      }

      final firstName = customer['firstname']?.toString() ?? '';
      final lastName = customer['lastname']?.toString() ?? '';
      final customerName = '$firstName $lastName'.trim();

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProviderRatingDialog(
            serviceId: serviceId,
            userId: userId,
            providerName: customerName.isNotEmpty ? customerName : 'Customer',
          );
        },
      );

      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text('Rating submitted successfully!'),
                ],
              ),
              backgroundColor: ColorConstant.moyoGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _fetchCompletedServicesWithoutLoading();
      }
    } catch (e) {
      print('Error showing rating dialog: $e');
      _showErrorSnackBar('An error occurred');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ColorConstant.appColor,
        ),
      );
    }
  }

  Future<void> _fetchCompletedServicesWithoutLoading() async {
    try {
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$base_url/bid/api/service/provider-service-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Response: .....${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            services = data['services'] ?? [];
          });
        }
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  void _toggleExpand(int index) {
    if (mounted) {
      setState(() {
        if (expandedCards.contains(index)) {
          expandedCards.remove(index);
        } else {
          expandedCards.add(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        title: Text(
          'Completed Services',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: ColorConstant.white,
          ),
        ),
        backgroundColor: ColorConstant.appColor,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorConstant.white),
      ),
      body: isLoading
          ? _buildLoading()
          : services.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchCompletedServices,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return service != null
                ? _buildServiceCard(service, index)
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.appColor),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading services...',
            style: TextStyle(fontSize: 16.sp, color: ColorConstant.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80.sp,
            color: ColorConstant.buttonBg,
          ),
          SizedBox(height: 16.h),
          Text(
            'No services yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: ColorConstant.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your services will appear here',
            style: TextStyle(fontSize: 16.sp, color: ColorConstant.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service, int index) {
    if (service == null) return SizedBox.shrink();

    final customer = service['customer'];
    if (customer == null) return SizedBox.shrink();

    final dynamicFields = service['dynamic_fields'] as Map<String, dynamic>? ?? {};
    final isExpanded = expandedCards.contains(index);
    final status = service['status']?.toString() ?? 'unknown';
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';
    final ratingGiven = service['rating_given'] == true;

    // Determine colors and text based on status
    final headerColor = isCancelled
        ? Colors.red
        : ColorConstant.moyoGreen;

    final statusIcon = isCancelled
        ? Icons.cancel
        : Icons.verified;

    final statusText = isCancelled
        ? 'Cancelled'
        : 'Completed';

    final statusDate = isCancelled
        ? (service['cancelled_at'] != null
        ? _formatDate(service['cancelled_at'].toString())
        : (service['updated_at'] != null
        ? _formatDate(service['updated_at'].toString())
        : ''))
        : (service['ended_at'] != null
        ? _formatDate(service['ended_at'].toString())
        : '');

    final serviceTitle = service['title']?.toString() ?? 'Service';
    final finalAmount = service['final_amount']?.toString() ??
        service['budget']?.toString() ?? '0';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.black.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: () => _toggleExpand(index),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16.r),
              bottom: isExpanded ? Radius.zero : Radius.circular(16.r),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                  bottom: isExpanded ? Radius.zero : Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: ColorConstant.white,
                    child: Icon(
                      statusIcon,
                      color: headerColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceTitle,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.white,
                          ),
                        ),
                        Text(
                          '$statusText${statusDate.isNotEmpty ? ' • $statusDate' : ''}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: ColorConstant.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstant.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '₹$finalAmount',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ColorConstant.white,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Customer Info
                  _buildCustomerInfo(customer),

                  SizedBox(height: 16.h),

                  // Service Details
                  _buildServiceDetails(service),

                  // Show cancellation reason if cancelled
                  if (isCancelled && service['cancel_reason'] != null)
                    _buildCancellationReason(service['cancel_reason'].toString()),

                  if (dynamicFields.isNotEmpty)
                    _buildDynamicFields(dynamicFields),

                  // Rating Section - Only show if completed AND rating NOT given
                  if (isCompleted && !ratingGiven)
                    _buildRatingSection(service),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(dynamic customer) {
    final imageUrl = customer['image']?.toString();
    final firstName = customer['firstname']?.toString() ?? '';
    final lastName = customer['lastname']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
            imageUrl,
            width: 48.w,
            height: 48.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
          )
              : _buildDefaultAvatar(),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName.isNotEmpty ? fullName : 'Customer',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48.w,
      height: 48.h,
      color: ColorConstant.buttonBg,
      child: Icon(
        Icons.person,
        size: 24.sp,
        color: ColorConstant.darkPrimary,
      ),
    );
  }

  Widget _buildServiceDetails(dynamic service) {
    final location = service['location']?.toString();
    final durationValue = service['duration_value'];
    final durationUnit = service['duration_unit']?.toString();
    final scheduleDate = service['schedule_date']?.toString();
    final scheduleTime = service['schedule_time']?.toString();

    return Column(
      children: [
        if (location != null && location.isNotEmpty)
          _buildDetailRow(
            Icons.location_on_outlined,
            'Location',
            location,
          ),

        if (durationValue != null && durationUnit != null) ...[
          SizedBox(height: 12.h),
          _buildDetailRow(
            Icons.schedule_outlined,
            'Duration',
            '$durationValue ${durationUnit}',
          ),
        ],

        if (scheduleDate != null && scheduleTime != null) ...[
          SizedBox(height: 12.h),
          _buildDetailRow(
            Icons.access_time_outlined,
            'Scheduled',
            _formatDateTime(scheduleDate, scheduleTime),
          ),
        ],
      ],
    );
  }

  Widget _buildCancellationReason(String reason) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18.sp,
                  color: Colors.red.shade700,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Cancellation Reason',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorConstant.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFields(Map<String, dynamic> dynamicFields) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorConstant.moyoOrangeFade,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ColorConstant.buttonBg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dynamicFields.entries.map<Widget>((entry) {
            final key = entry.key?.toString() ?? '';
            final value = entry.value?.toString() ?? '';

            if (key.isEmpty) return SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6.sp,
                    color: ColorConstant.moyoGreen,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$key:',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                        if (value.isNotEmpty)
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorConstant.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRatingSection(dynamic service) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Color(0xFFFFA726).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.star_rate_rounded,
                    color: Color(0xFFFFA726),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate Your Experience',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      Text(
                        'Share your feedback about this service',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRatingDialog(service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.rate_review, size: 18.sp),
                label: Text(
                  'Rate Customer',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: ColorConstant.moyoOrangeFade,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: ColorConstant.appColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: ColorConstant.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error parsing date: $e');
      return '';
    }
  }

  String _formatDateTime(String? dateString, String? timeString) {
    if (dateString == null || dateString.isEmpty ||
        timeString == null || timeString.isEmpty) return '';
    try {
      final formattedDate = _formatDate(dateString);
      return formattedDate.isNotEmpty ? '$formattedDate at $timeString' : '';
    } catch (e) {
      print('Error formatting datetime: $e');
      return '';
    }
  }
}