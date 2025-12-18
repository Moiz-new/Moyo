import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colorConstant/color_constant.dart';

class UserMyRating extends StatefulWidget {
  const UserMyRating({Key? key}) : super(key: key);

  @override
  State<UserMyRating> createState() => _UserMyRatingState();
}

class _UserMyRatingState extends State<UserMyRating> {
  bool isLoading = true;
  Map<String, dynamic>? ratingData;
  List<dynamic> individualRatings = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchAverageRatings(), fetchIndividualRatings()]);
  }

  Future<void> fetchAverageRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$base_url/bid/api/user/average'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ratingData = data;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load average ratings';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchIndividualRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final providerId = prefs.getInt('user_id');

      if (providerId == null) {
        setState(() {
          errorMessage = 'Provider ID not found';
          isLoading = false;
        });
        return;
      }

      print(providerId);
      final response = await http.get(
        Uri.parse('$base_url/bid/api/user/user/$providerId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['success'] == true && data['data'] != null) {
            individualRatings = data['data'];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load individual ratings';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Map<int, int> _calculateRatingDistribution() {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var rating in individualRatings) {
      int stars = rating['rating'] ?? 0;
      if (stars >= 1 && stars <= 5) {
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: ColorConstant.onSurface, size: 20.sp),
        ),
        title: Text(
          'My Ratings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: ColorConstant.onSurface,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorConstant.moyoOrangeFade.withOpacity(0.15),
              ColorConstant.scaffoldGray,
            ],
          ),
        ),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: ColorConstant.moyoOrange,
            strokeWidth: 3,
          ),
        )
            : errorMessage != null
            ? _buildErrorWidget()
            : _buildRatingContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red.shade400),
            SizedBox(height: 12.h),
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 14.sp, color: ColorConstant.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                fetchData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: ColorConstant.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingContent() {
    final averageRating = ratingData?['average_rating']?.toDouble() ?? 0.0;
    final totalRatings = ratingData?['total_ratings'] ?? individualRatings.length;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Rating Overview Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorConstant.moyoOrange,
                    ColorConstant.moyoOrange.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstant.moyoOrange.withOpacity(0.25),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rating Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.white,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: List.generate(5, (index) {
                          if (index < averageRating.floor()) {
                            return Icon(Icons.star_rounded, color: ColorConstant.white, size: 18.sp);
                          } else if (index < averageRating) {
                            return Icon(Icons.star_half_rounded, color: ColorConstant.white, size: 18.sp);
                          } else {
                            return Icon(Icons.star_outline_rounded, color: ColorConstant.white.withOpacity(0.5), size: 18.sp);
                          }
                        }),
                      ),
                    ],
                  ),
                  SizedBox(width: 20.w),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Rating',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: ColorConstant.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '$totalRatings ${totalRatings == 1 ? 'Review' : 'Reviews'}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Compact Rating Breakdown
            _buildCompactRatingBreakdown(),
            SizedBox(height: 20.h),

            // Reviews Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.onSurface,
                  ),
                ),
                if (individualRatings.isNotEmpty)
                  Text(
                    '${individualRatings.length} total',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: ColorConstant.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Individual Reviews
            if (individualRatings.isNotEmpty) ...[
              ...individualRatings.map((rating) => _buildCompactReviewCard(rating)).toList(),
            ] else ...[
              Container(
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: ColorConstant.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 40.sp,
                        color: ColorConstant.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorConstant.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactReviewCard(dynamic rating) {
    final stars = rating['rating'] ?? 0;
    final review = rating['review'] ?? 'No review text';
    final createdAt = rating['created_at'] ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (e) {
      date = null;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < stars
                        ? ColorConstant.moyoOrange
                        : ColorConstant.onSurface.withOpacity(0.25),
                    size: 16.sp,
                  );
                }),
              ),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ColorConstant.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            review,
            style: TextStyle(
              fontSize: 13.sp,
              color: ColorConstant.onSurface.withOpacity(0.85),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRatingBreakdown() {
    final distribution = _calculateRatingDistribution();
    final total = individualRatings.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: ColorConstant.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...List.generate(5, (index) {
            final stars = 5 - index;
            final count = distribution[stars] ?? 0;
            final percentage = total > 0 ? count / total : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8.h),
              child: _buildCompactRatingBar(stars, percentage, count),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactRatingBar(int stars, double percentage, int count) {
    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: ColorConstant.onSurface,
          ),
        ),
        SizedBox(width: 3.w),
        Icon(Icons.star, size: 13.sp, color: ColorConstant.moyoOrange),
        SizedBox(width: 8.w),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: ColorConstant.moyoOrangeFade.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.moyoOrange),
              minHeight: 6.h,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 50.w,
          child: Text(
            '${(percentage * 100).toInt()}% ($count)',
            style: TextStyle(
              fontSize: 11.sp,
              color: ColorConstant.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}