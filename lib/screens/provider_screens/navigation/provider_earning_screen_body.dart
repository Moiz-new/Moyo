import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/colorConstant/color_constant.dart';
import 'EarningsProvider.dart';
import 'EarningsResponse.dart';

class ProviderEarningScreen extends StatefulWidget {
  const ProviderEarningScreen({Key? key}) : super(key: key);

  @override
  State<ProviderEarningScreen> createState() => _ProviderEarningScreenState();
}

class _ProviderEarningScreenState extends State<ProviderEarningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsProvider>().fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      body: SafeArea(
        child: Consumer<EarningsProvider>(
          builder: (context, earningsProvider, child) {
            if (earningsProvider.isLoading &&
                earningsProvider.earningsData == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: ColorConstant.moyoOrange,
                ),
              );
            }

            if (earningsProvider.errorMessage != null &&
                earningsProvider.earningsData == null) {
              print(earningsProvider.errorMessage);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        earningsProvider.errorMessage ?? 'An error occurred',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.sp, color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => earningsProvider.fetchEarnings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.moyoOrange,
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: ColorConstant.moyoOrange,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today\'s Earnings',
                              style: TextStyle(
                                color: ColorConstant.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showDatePicker(
                                    context,
                                    earningsProvider,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorConstant.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          earningsProvider.getFormattedDate(),
                                          style: TextStyle(
                                            color: ColorConstant.black,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: ColorConstant.black,
                                          size: 16.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '₹${earningsProvider.getTodayEarnings().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: ColorConstant.white,
                            fontSize: 35.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              'This Week',
                              '₹${earningsProvider.getWeekEarnings().toStringAsFixed(0)}',
                            ),
                            _buildStatItem(
                              'This Month',
                              '₹${earningsProvider.getMonthEarnings().toStringAsFixed(0)}',
                            ),
                            _buildStatItem(
                              'Jobs Done',
                              '${earningsProvider.getTotalServices()}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          'Recent Earnings',
                          style: TextStyle(
                            color: ColorConstant.black,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Expanded(child: _buildServicesList(earningsProvider)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorConstant.white.withOpacity(0.9),
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: ColorConstant.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(EarningsProvider provider) {
    final filteredServices = provider.getFilteredServices();

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 60.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 18.sp,
                color: ColorConstant.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'No services found for ${provider.getFormattedDate()}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _showDatePicker(context, provider),
              icon: Icon(Icons.date_range, size: 18.sp),
              label: Text('Select Different Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchEarnings(),
      color: ColorConstant.moyoOrange,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildEarningItem(filteredServices[index]),
          );
        },
      ),
    );
  }

  Widget _buildEarningItem(ServiceEarning serviceEarning) {
    final service = serviceEarning.service;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getIconForCategory(service?.category ?? ''),
                  color: Color(0xFF4CAF50),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service?.title ?? 'Service',
                      style: TextStyle(
                        color: ColorConstant.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service?.category ?? 'N/A',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${double.tryParse(serviceEarning.totalAmount ?? '0')?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      color: ColorConstant.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        service?.status ?? '',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      service?.status ?? 'N/A',
                      style: TextStyle(
                        color: _getStatusColor(service?.status ?? ''),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time,
                  'Time',
                  serviceEarning.getFormattedTime(),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today,
                  'Date',
                  serviceEarning.getRelativeTime(),
                ),
              ),
            ],
          ),
          if (service?.location != null) ...[
            SizedBox(height: 8.h),
            _buildDetailItem(
              Icons.location_on_outlined,
              'Location',
              service!.location!,
            ),
          ],
          if (service?.durationValue != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.timer_outlined,
                    'Duration',
                    '${service!.durationValue} ${service.durationUnit ?? 'hrs'}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.payment,
                    'Payment',
                    service.paymentMethod ?? 'N/A',
                  ),
                ),
              ],
            ),
          ],
          if (service?.dynamicFields != null &&
              service!.dynamicFields!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: 12.h),
            Text(
              'Service Details',
              style: TextStyle(
                color: ColorConstant.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...service.dynamicFields!.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${entry.key}: ',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: '${entry.value}',
                              style: TextStyle(
                                color: ColorConstant.black,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: ColorConstant.black,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'shepherd':
        return Icons.pets_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'painting':
        return Icons.format_paint_outlined;
      case 'carpentry':
        return Icons.construction_outlined;
      default:
        return Icons.home_repair_service_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showDatePicker(BuildContext context, EarningsProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstant.moyoOrange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != provider.selectedDate) {
      provider.setDate(picked);
    }
  }
}
