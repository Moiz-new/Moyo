import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../BannerModel.dart';
import '../../../widgets/image_slider.dart';
import '../../SubCategory/SelectFromHomeScreen.dart';
import '../../user_screens/Home/CategoryProvider.dart';
import '../../Skills/ProviderMySkillScreen.dart';
import '../../SubCategory/SubcategoryScreen.dart';

class ProviderHomeScreenBody extends StatefulWidget {
  const ProviderHomeScreenBody({super.key});

  @override
  State<ProviderHomeScreenBody> createState() => _ProviderHomeScreenBodyState();
}

class _ProviderHomeScreenBodyState extends State<ProviderHomeScreenBody> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<CarouselProvider>().fetchCarousels(type: 'provider');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
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
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Switch.adaptive(
                    thumbColor: WidgetStateProperty.all(ColorConstant.white),
                    activeTrackColor: ColorConstant.moyoGreen,
                    inactiveTrackColor: ColorConstant.scaffoldGray,
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.white.withOpacity(0),
                    ),
                    value: isOnline,
                    onChanged: (value) {
                      setState(() {
                        isOnline = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                spacing: 10,
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
                  GestureDetector(
                    onTap: isOnline
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderMySkillScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 10,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: ColorConstant.moyoOrangeFade,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    color: ColorConstant.moyoOrange,
                                  ),
                                  Text(
                                    'Max 10 ',
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
                                  Text(
                                    'Job Offering ',
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
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Color(0xFFDEF0FC),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    color: Color(0xFF2196F3),
                                  ),
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
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Color(0xFFFFF6D9),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Icon(Icons.star, color: Color(0xFFFEC00B)),
                                  Text(
                                    '''Our Ratings''',
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Section - Now using API data
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

                // Extract image URLs from carousel data
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

            Consumer<CategoryProvider>(
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
                              categoryProvider.fetchCategories();
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
                      return _categoryCard(
                        context,
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

  Widget _categoryCard(
    BuildContext context, {
    required dynamic category,
    required CategoryProvider categoryProvider,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    final imageUrl = category.icon != null && category.icon.isNotEmpty
        ? category.icon
        : null;

    return Opacity(
      opacity: isOnline ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: isOnline
            ? () {
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
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          width: (screenWidth - 80) / 4,
          decoration: BoxDecoration(
            color: Color(0xFFF7E5D1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
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
              Text(
                category.name ?? "Category",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Color(0xFF000000),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
