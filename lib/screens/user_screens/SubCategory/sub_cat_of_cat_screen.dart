import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Home/CatehoryModel.dart';
import '../User Instant Service/user_instant_service_screen.dart';
import 'SubCategoryProvider.dart';

class SubCatOfCatScreen extends StatefulWidget {
  const SubCatOfCatScreen({super.key});

  @override
  State<SubCatOfCatScreen> createState() => _SubCatOfCatScreenState();
}

class _SubCatOfCatScreenState extends State<SubCatOfCatScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Category) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SubCategoryProvider>().fetchSubcategories(arguments.id);
      });
    } else if (arguments is Map<String, dynamic>) {
      final categoryId = arguments['id'] ?? arguments['categoryId'];
      if (categoryId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SubCategoryProvider>().fetchSubcategories(categoryId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final categoryName = arguments is Category
        ? arguments.name
        : 'Sub Categories';

    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: categoryName),
      body: _subCategory(context),
    );
  }

  Widget _subCategory(BuildContext context) {
    return Consumer<SubCategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
                  SizedBox(height: 16.h),
                  Text(
                    provider.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 16.sp, color: Colors.red),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      final arguments = ModalRoute.of(context)?.settings.arguments;
                      if (arguments is Category) {
                        provider.fetchSubcategories(arguments.id);
                      } else if (arguments is Map<String, dynamic>) {
                        final categoryId = arguments['id'] ?? arguments['categoryId'];
                        if (categoryId != null) {
                          provider.fetchSubcategories(categoryId);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.subcategories.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No subcategories available',
                    style: GoogleFonts.roboto(fontSize: 18.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8.w),
          itemCount: provider.subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = provider.subcategories[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6.h),
              child: UserExpansionTileListCard(subcategory: subcategory),
            );
          },
        );
      },
    );
  }
}

class UserExpansionTileListCard extends StatelessWidget {
  final SubCategory subcategory;

  const UserExpansionTileListCard({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100.r)),
              height: 45.w,
              width: 45.w,
              child: CachedNetworkImage(
                imageUrl: subcategory.icon,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Image.asset('assets/images/moyo_image_placeholder.png'),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/images/moyo_image_placeholder.png'),
              ),
            ),
            title: Text(
              subcategory.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '₹${subcategory.hourlyRate}/hr',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPricingInfo(constraints.maxWidth),
                          SizedBox(height: 16.h),
                          Text(
                            'Choose Service Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: ColorConstant.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildServiceButtons(context),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingInfo(double maxWidth) {
    final isSmallScreen = maxWidth < 320.w;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pricing Details',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // Hourly & Daily Row/Column
          _buildPricingRow(
            isSmallScreen,
            [
              _PriceItem(label: 'Hourly', price: subcategory.hourlyRate),
              _PriceItem(label: 'Daily', price: subcategory.dailyRate),
            ],
          ),

          SizedBox(height: 8.h),

          // Weekly & Monthly Row/Column
          _buildPricingRow(
            isSmallScreen,
            [
              _PriceItem(label: 'Weekly', price: subcategory.weeklyRate),
              _PriceItem(label: 'Monthly', price: subcategory.monthlyRate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(bool isSmallScreen, List<Widget> items) {
    if (isSmallScreen) {
      return Column(
        children: items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            children: [Expanded(child: item)],
          ),
        )).toList(),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) => Expanded(child: item)).toList(),
    );
  }

  Widget _buildServiceButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleServiceTypeSelection(context, 'instant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.moyoOrange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 2,
            ),
            child: Text(
              'Instant',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleServiceTypeSelection(context, 'later'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorConstant.moyoOrange, width: 2),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Later',
              style: TextStyle(
                color: ColorConstant.moyoOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _handleServiceTypeSelection(BuildContext context, String serviceType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInstantServiceScreen(
          categoryId: subcategory.id,
          categoryName: subcategory.name,
        ),
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  final String label;
  final String price;

  const _PriceItem({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            '₹$price',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
