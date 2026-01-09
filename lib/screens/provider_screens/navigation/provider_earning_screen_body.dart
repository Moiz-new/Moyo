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
                              'Earnings',
                              style: TextStyle(
                                color: ColorConstant.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showFilterOptions(
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
                        SizedBox(height: 4.h),
                        Text(
                          '₹${_calculateTotalEarnings(earningsProvider)}',
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
                              'Today',
                              '₹${earningsProvider.getTodayEarnings().toStringAsFixed(0)}',
                            ),
                            _buildStatItem(
                              'This Week',
                              '₹${earningsProvider.getWeekEarnings().toStringAsFixed(0)}',
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

  String _calculateTotalEarnings(EarningsProvider provider) {
    final services = provider.getFilteredServices();
    double total = 0.0;
    for (var service in services) {
      total += double.tryParse(service.totalAmount ?? '0') ?? 0.0;
    }
    return total.toStringAsFixed(0);
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
              onPressed: () => _showFilterOptions(context, provider),
              icon: Icon(Icons.date_range, size: 18.sp),
              label: Text('Change Filter'),
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
                  _getIconForService(serviceEarning.serviceTitle ?? ''),
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
                      serviceEarning.serviceTitle ?? 'Service',
                      style: TextStyle(
                        color: ColorConstant.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          serviceEarning.getFormattedTime(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
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
                  Icons.calendar_today,
                  'Date',
                  serviceEarning.getFormattedDate(),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.timer_outlined,
                  'Duration',
                  serviceEarning.getDuration(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.currency_rupee,
                  'Base Fare',
                  '₹${double.tryParse(serviceEarning.baseFare ?? '0')?.toStringAsFixed(0) ?? '0'}',
                ),
              ),
              /*Expanded(
                child: _buildDetailItem(
                  Icons.schedule,
                  'Waiting Time',
                  '${serviceEarning.waitingMinutes ?? 0} min',
                ),
              ),*/
            ],
          ),
          if (serviceEarning.waitingCharges != null &&
              serviceEarning.waitingCharges! > 0) ...[
            SizedBox(height: 8.h),
            _buildDetailItem(
              Icons.money,
              'Waiting Charges',
              '₹${serviceEarning.waitingCharges}',
            ),
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

  IconData _getIconForService(String serviceTitle) {
    final title = serviceTitle.toLowerCase();
    if (title.contains('maid') || title.contains('cleaning')) {
      return Icons.cleaning_services_outlined;
    } else if (title.contains('driver')) {
      return Icons.local_taxi_outlined;
    } else if (title.contains('plumb')) {
      return Icons.plumbing_outlined;
    } else if (title.contains('electric')) {
      return Icons.electrical_services_outlined;
    } else if (title.contains('paint')) {
      return Icons.format_paint_outlined;
    } else if (title.contains('carpenter') || title.contains('carpentry')) {
      return Icons.construction_outlined;
    } else if (title.contains('shepherd') || title.contains('pet')) {
      return Icons.pets_outlined;
    } else {
      return Icons.home_repair_service_outlined;
    }
  }

  void _showFilterOptions(BuildContext context, EarningsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Select Filter',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.black,
                ),
              ),
              SizedBox(height: 20.h),
              _buildFilterOption(
                context,
                provider,
                'All Time',
                Icons.all_inclusive,
                FilterType.all,
              ),
              _buildFilterOption(
                context,
                provider,
                'By Day',
                Icons.calendar_today,
                FilterType.day,
              ),
              _buildFilterOption(
                context,
                provider,
                'By Month',
                Icons.calendar_month,
                FilterType.month,
              ),
              _buildFilterOption(
                context,
                provider,
                'Date Range',
                Icons.date_range,
                FilterType.range,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
      BuildContext context,
      EarningsProvider provider,
      String title,
      IconData icon,
      FilterType filterType,
      ) {
    final isSelected = provider.filterType == filterType;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);

        if (filterType == FilterType.day) {
          final picked = await showDatePicker(
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
          if (picked != null) {
            provider.setFilterType(FilterType.day);
            provider.setDate(picked);
          }
        } else if (filterType == FilterType.month) {
          final picked = await showDatePicker(
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
          if (picked != null) {
            provider.setFilterType(FilterType.month);
            provider.setDate(picked);
          }
        } else if (filterType == FilterType.range) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: provider.rangeStartDate != null &&
                provider.rangeEndDate != null
                ? DateTimeRange(
              start: provider.rangeStartDate!,
              end: provider.rangeEndDate!,
            )
                : null,
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
          if (picked != null) {
            provider.setDateRange(picked.start, picked.end);
          }
        } else {
          provider.setFilterType(filterType);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.moyoOrange.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? ColorConstant.moyoOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorConstant.moyoOrange : Colors.grey[600],
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                  isSelected ? ColorConstant.moyoOrange : ColorConstant.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorConstant.moyoOrange,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}