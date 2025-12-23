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
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('provider_auth_token');
    if (token != null) {
      await _fetchCompletedServices();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchCompletedServices() async {
    try {
      final response = await http.get(
        Uri.parse('$base_url/bid/api/service/provider-service-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = data['services'] ?? [];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _showRatingDialog(dynamic service) async {
    final customer = service['customer'];
    final userId = service['user_id']?.toString();
    final serviceId = service['id']?.toString();

    if (userId == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to rate this service. Missing required information.',
          ),
          backgroundColor: ColorConstant.appColor,
        ),
      );
      return;
    }

    final customerName =
        '${customer['firstname'] ?? ''} ${customer['lastname'] ?? ''}'.trim();

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
      await _fetchCompletedServices();
    }
  }

  void _toggleExpand(int index) {
    setState(() {
      if (expandedCards.contains(index)) {
        expandedCards.remove(index);
      } else {
        expandedCards.add(index);
      }
    });
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
                itemBuilder: (context, index) =>
                    _buildServiceCard(services[index], index),
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
            'Loading completed services...',
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
            'No completed services yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: ColorConstant.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your completed services will appear here',
            style: TextStyle(fontSize: 16.sp, color: ColorConstant.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(service, int index) {
    final customer = service['customer'];
    final dynamicFields = service['dynamic_fields'] ?? {};
    final isExpanded = expandedCards.contains(index);
    final ratingGiven = service['rating_given'] ?? false; // Get rating status

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
                color: ColorConstant.moyoGreen,
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
                      Icons.verified,
                      color: ColorConstant.moyoGreen,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${service['title'] ?? 'Service'}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.white,
                          ),
                        ),
                        Text(
                          'Completed • ${service['ended_at'] != null ? _formatDate(service['ended_at']) : ''}',
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
                      '₹${service['budget'] ?? '0'}',
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
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: customer['image'] != null
                            ? Image.network(
                          customer['image'],
                          width: 48.w,
                          height: 48.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48.w,
                            height: 48.h,
                            color: ColorConstant.buttonBg,
                            child: Icon(
                              Icons.person,
                              size: 24.sp,
                              color: ColorConstant.darkPrimary,
                            ),
                          ),
                        )
                            : Container(
                          width: 48.w,
                          height: 48.h,
                          color: ColorConstant.buttonBg,
                          child: Icon(
                            Icons.person,
                            size: 24.sp,
                            color: ColorConstant.darkPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${customer['firstname'] ?? ''} ${customer['lastname'] ?? ''}',
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
                  ),

                  SizedBox(height: 16.h),

                  // Service Details
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Location',
                    service['location'] ?? '',
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    Icons.schedule_outlined,
                    'Duration',
                    '${service['duration_value'] ?? 0} ${service['duration_unit'] ?? 'hr'}',
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    Icons.access_time_outlined,
                    'Scheduled',
                    _formatDateTime(
                      service['schedule_date'],
                      service['schedule_time'],
                    ),
                  ),

                  if (dynamicFields.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: ColorConstant.moyoOrangeFade,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ColorConstant.buttonBg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...dynamicFields.entries.map<Widget>((entry) {
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${entry.key}:',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstant.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '${entry.value}',
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
                        ],
                      ),
                    ),
                  ],

                  // Rating Section - Only show if rating NOT given
                  if (!ratingGiven) ...[
                    SizedBox(height: 20.h),
                    Container(
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
                  ],
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
    if (dateString == null) return '';
    final date = DateTime.parse(dateString).toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(String? dateString, String? timeString) {
    if (dateString == null || timeString == null) return '';
    final date = DateTime.parse(dateString).toLocal();
    return '${_formatDate(dateString)} at $timeString';
  }
}
