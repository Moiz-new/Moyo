import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../BannerModel.dart';
import '../../../widgets/image_slider.dart';
import '../SubCategory/SubCategoryProvider.dart';
import 'CategoryProvider.dart';

class UserHomeScreenBody extends StatefulWidget {
  const UserHomeScreenBody({super.key});

  @override
  State<UserHomeScreenBody> createState() => _UserHomeScreenBodyState();
}

class _UserHomeScreenBodyState extends State<UserHomeScreenBody> {
  @override
  void initState() {
    super.initState();
    // Fetch categories and carousels when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<CarouselProvider>().fetchCarousels(
        type: 'user',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        child: Column(
          spacing: 10,
          children: [
            // Carousel Section - Now using API data with type "user"
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
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              carouselProvider.fetchCarousels(type: 'user');
                            },
                            child: Text('Retry'),
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

            SizedBox(
              width: double.infinity,
              child: Text(
                "Service Offering",
                textAlign: TextAlign.start,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                // Show loading indicator
                if (categoryProvider.isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Show error message
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

                // Show empty state
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

                // Show categories
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

    // Get the full image URL - icon already contains full S3 URL from API
    final imageUrl = category.icon != null && category.icon.isNotEmpty
        ? category
              .icon // Icon already contains full S3 URL
        : null;

    return InkWell(

        onTap: () {
      // Clear previous subcategories before navigating
      context.read<SubCategoryProvider>().clearSubcategories();

      // Navigate and pass the entire category object
      Navigator.pushNamed(
          context,
          '/SubCatOfCatScreen',
          arguments: category
      );
    },
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
    );
  }
}
