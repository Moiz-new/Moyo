import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/screens/provider_screens/navigation/ProviderRatingScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../BannerModel.dart';
import '../../../NotificationService.dart';
import '../../../widgets/image_slider.dart';
import '../../SubCategory/SelectFromHomeScreen.dart';
import '../../user_screens/Home/CategoryProvider.dart';
import '../../Skills/ProviderMySkillScreen.dart';
import '../../SubCategory/SubcategoryScreen.dart';
import '../../user_screens/Home/ProviderCategoryProvider.dart';
import '../CompletedServicesScreen.dart';
import 'AvailabilityProvider.dart';

class ProviderHomeScreenBody extends StatefulWidget {
  const ProviderHomeScreenBody({super.key});

  @override
  State<ProviderHomeScreenBody> createState() => _ProviderHomeScreenBodyState();
}

class _ProviderHomeScreenBodyState extends State<ProviderHomeScreenBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderCategoryProvider>().fetchCategories(context: context);
      context.read<CarouselProvider>().fetchCarousels(type: 'provider');
      context.read<AvailabilityProvider>().initializeAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<AvailabilityProvider>(
              builder: (context, availabilityProvider, child) {
                final isOnline = availabilityProvider.isAvailable;

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            isOnline ? "You are online" : "You are offline",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.roboto(
                              textStyle: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    color: isOnline
                                        ? ColorConstant.moyoGreen
                                        : Colors.grey.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          Switch.adaptive(
                            thumbColor: WidgetStateProperty.all(
                              ColorConstant.white,
                            ),
                            activeTrackColor: ColorConstant.moyoGreen,
                            inactiveTrackColor: Colors.grey,
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.white.withOpacity(0),
                            ),
                            value: isOnline,
                            onChanged: availabilityProvider.isLoading
                                ? null
                                : (value) async {
                                    await availabilityProvider
                                        .toggleAvailability();

                                    if (availabilityProvider.errorMessage !=
                                        null) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              availabilityProvider
                                                      .errorMessage ??
                                                  'An error occurred',
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                        availabilityProvider.clearError();
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    if (availabilityProvider.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorConstant.moyoGreen,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 10),
            Consumer<AvailabilityProvider>(
              builder: (context, availabilityProvider, child) {
                final isOnline = availabilityProvider.isAvailable;

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Today's Stats",
                          textAlign: TextAlign.start,
                          style: GoogleFonts.roboto(
                            textStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 18,
                                  color: ColorConstant.black,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ✅ Card 1: Job Offering - SIRF YEH DISABLE HOGA
                            Expanded(
                              child: Opacity(
                                opacity: isOnline ? 1.0 : 0.5,
                                child: GestureDetector(
                                  onTap: isOnline
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProviderMySkillScreen(),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: ColorConstant.moyoOrangeFade,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 7.h),
                                        Icon(
                                          Icons.business_center_outlined,
                                          color: isOnline
                                              ? ColorConstant.moyoOrange
                                              : Colors.grey,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Max 10 ',
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: isOnline
                                                    ? ColorConstant.black
                                                    : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          'Job Offering ',
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: isOnline
                                                    ? ColorConstant.black
                                                    : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            // ✅ Card 2: Service Completed - HAMESHA ENABLE
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CompletedServicesScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Color(0xFFDEF0FC),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 10.h),
                                      Icon(
                                        Icons.work_outline,
                                        color: Color(0xFF2196F3),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Service Completed',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: ColorConstant.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProviderRatingScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Color(0xFFFFF6D9),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 10.h),
                                      Icon(
                                        Icons.star,
                                        color: Color(0xFFFEC00B),
                                      ),
                                      Text(
                                        'My Ratings',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: ColorConstant.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Carousel Section
            Consumer<CarouselProvider>(
              builder: (context, carouselProvider, child) {
                if (carouselProvider.isLoading) {
                  return Container(
                    height: 160,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (carouselProvider.errorMessage != null) {
                  return Container(
                    height: 160,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load carousel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (carouselProvider.carousels.isEmpty) {
                  return Container(
                    height: 160,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'No carousel items available',
                        style: GoogleFonts.roboto(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                final imageLinks = carouselProvider.carousels
                    .map((carousel) => carousel.imageUrl)
                    .toList();

                return ImageSlider(imageLinks: imageLinks);
              },
            ),

            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                "Moyo Offering's",
                textAlign: TextAlign.start,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            Consumer<ProviderCategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (categoryProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            categoryProvider.errorMessage ??
                                'An error occurred',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              categoryProvider.fetchCategories(
                                context: context,
                              );
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (categoryProvider.categories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No categories available',
                        style: GoogleFonts.roboto(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 16,
                    runSpacing: 16,
                    children: categoryProvider.categories.map((category) {
                      return _ProviderCategoryCard(
                        category: category,
                        categoryProvider: categoryProvider,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCategoryCard extends StatelessWidget {
  final dynamic category;
  final ProviderCategoryProvider categoryProvider;

  const _ProviderCategoryCard({
    required this.category,
    required this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    final cardWidth = (screenWidth - 20 - 48) / 4;

    final imageUrl = category.icon != null && category.icon.isNotEmpty
        ? category.icon
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectFromHomeScreen(
              categoryId: category.id,
              categoryName: category.name ?? "Category",
              categoryIcon: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        width: cardWidth,
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFFF7E5D1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              height: 48,
              width: 48,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        'assets/images/moyo_service_placeholder.png',
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/moyo_service_placeholder.png',
                      ),
                    )
                  : Image.asset('assets/images/moyo_service_placeholder.png'),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name ?? "Category",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Color(0xFF000000),
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
