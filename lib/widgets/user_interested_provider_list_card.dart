import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserInterestedProviderListCard extends StatelessWidget {
  final String? providerName;
  final String? gender;
  final String? age;
  final String? distance;
  final String? reachTime;

  ///
  final String? category;
  final String? subCategory;

  ///
  final String? chargeRate;
  final bool? isVerified;
  final String? rating;
  final String? experience;

  ///
  final String? dp;
  final VoidCallback? onBook;

  final double? remainingTime;
  final String? bidStatus;

  const UserInterestedProviderListCard({
    super.key,
    this.providerName,
    this.gender,
    this.age,
    this.distance,
    this.reachTime,
    this.category,
    this.subCategory,
    this.chargeRate,
    this.isVerified,
    this.rating,
    this.experience,
    this.dp,
    this.remainingTime,
    this.onBook,
    this.bidStatus,
  });

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Color(0xFF328303);
      case 'rebid':
        return ColorConstant.moyoOrange;
      case 'pending':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status background color
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Color(0xFFABF383);
      case 'rebid':
        return ColorConstant.moyoOrangeFade;
      case 'pending':
        return Colors.blue.withOpacity(0.15);
      case 'rejected':
        return Colors.red.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBook,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              _nameGenderAgeDistanceReachTime(
                context,
                providerName: providerName,
                gender: gender,
                age: age,
                distance: distance,
                reachTime: reachTime,
                bidStatus: bidStatus,
              ),
              _categorySubCategory(
                context,
                category: category,
                subCategory: subCategory,
              ),
              _chargesRateIsVerifiedRatingExperience(
                context,
                chargeRate: chargeRate,
                isVerified: isVerified,
                rating: rating,
                experience: experience,
              ),
              _bookProviderDp(
                context,
                dp: dp,
                onBook: onBook,
                remainingTime: remainingTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// module method
  Widget _nameGenderAgeDistanceReachTime(
    BuildContext context, {
    String? providerName,
    String? gender,
    String? age,
    String? distance,
    String? reachTime,
    String? bidStatus,
  }) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1.0.w),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    providerName ?? "no name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    "(${gender ?? "no gender"} - ${age ?? "No age"}years)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Color(0xFF808080),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Status Badge
          if (bidStatus != null && bidStatus!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(bidStatus!),
                borderRadius: BorderRadius.all(Radius.circular(50.r)),
                border: Border.all(
                  color: _getStatusColor(bidStatus!),
                  width: 1.w,
                ),
              ),
              child: Text(
                bidStatus!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                  color: _getStatusColor(bidStatus!),
                ),
              ),
            ),
          // Distance and Reach Time
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance ?? "No distance",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12.sp,
                  color: Colors.black.withAlpha(100),
                ),
              ),
              Text(
                "(${reachTime ?? "No reachTime"})",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11.sp,
                  color: Colors.black.withAlpha(100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categorySubCategory(
    BuildContext context, {
    String? category,
    String? subCategory,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Text(
        textAlign: TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        "${category ?? "No category"} • ${subCategory ?? "No subCategory"}",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 13.sp,
          color: Colors.black.withAlpha(100),
        ),
      ),
    );
  }

  _chargesRateIsVerifiedRatingExperience(
    BuildContext context, {
    String? chargeRate,
    bool? isVerified,
    String? rating,
    String? experience,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8.h,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "₹ ${chargeRate ?? "no chargeRate"}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: Color(0xFF1D1B20),
                ),
              ),
              SizedBox(width: 6.w),
              if (isVerified == true)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFABF383),
                    borderRadius: BorderRadius.all(Radius.circular(50.r)),
                  ),
                  child: Text(
                    "Verified",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: Color(0xFF328303),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorConstant.moyoOrangeFade,
                  borderRadius: BorderRadius.all(Radius.circular(50.r)),
                ),
                child: Text(
                  "⭐ ${rating ?? "no rating"}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorConstant.moyoOrangeFade,
                  borderRadius: BorderRadius.all(Radius.circular(50.r)),
                ),
                child: Text(
                  "${experience ?? "no rating"} yrs exp",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookProviderDp(
    BuildContext context, {
    String? dp,
    VoidCallback? onBook,
    double? remainingTime,
  }) {
    final progress = remainingTime != null
        ? (remainingTime / 30.0).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: remainingTime != null && remainingTime > 0 ? onBook : null,
            child: Container(
              width: 200.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Stack(
                children: [
                  // Progress background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: ColorConstant.moyoOrange,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Text overlay
                  Center(
                    child: Text(
                      remainingTime != null && remainingTime > 0
                          ? "Book this provider"
                          : "Expired",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        color: remainingTime != null && remainingTime > 0
                            ? Color(0xFFFFFFFF)
                            : Color(0xFF808080),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
            ),
            height: 54.h,
            width: 54.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: dp ?? "https://picsum.photos/200/200",
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Image.asset('assets/images/moyo_image_placeholder.png'),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/moyo_image_placeholder.png'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
