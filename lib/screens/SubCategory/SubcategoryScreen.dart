import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'SubcategoryDetailsScreen.dart';
import 'SubcategoryProvider.dart';

class SubcategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;

  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubcategoryProvider>().fetchSubcategories(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (widget.categoryIcon != null && widget.categoryIcon!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(right: 12),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFF7E5D1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.categoryIcon!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Icon(Icons.category, color: ColorConstant.moyoOrange),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.category, color: ColorConstant.moyoOrange),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                widget.categoryName,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ColorConstant.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<SubcategoryProvider>(
        builder: (context, subcategoryProvider, child) {
          if (subcategoryProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConstant.moyoOrange),
                  SizedBox(height: 16),
                  Text(
                    'Loading subcategories...',
                    style: GoogleFonts.roboto(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (subcategoryProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      subcategoryProvider.errorMessage ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        subcategoryProvider.fetchSubcategories(
                          widget.categoryId,
                        );
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.moyoOrange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (subcategoryProvider.subcategories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No subcategories available',
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'There are no services under this category yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                SizedBox(height: 20),

                // Subcategories Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: subcategoryProvider.subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory =
                        subcategoryProvider.subcategories[index];
                    return _buildSubcategoryCard(context, subcategory);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryCard(BuildContext context, dynamic subcategory) {
    final imageUrl = context.read<SubcategoryProvider>().getFullImageUrl(
      subcategory.icon,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryDetailsScreen(
              subcategory: subcategory,
              imageUrl: context.read<SubcategoryProvider>().getFullImageUrl(
                subcategory.icon,
              ), serviceName: widget.categoryName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF7E5D1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Center(
                                  child: Icon(
                                    Icons.room_service_outlined,
                                    size: 48,
                                    color: ColorConstant.moyoOrange.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.room_service_outlined,
                                    size: 48,
                                    color: ColorConstant.moyoOrange.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.room_service_outlined,
                                size: 48,
                                color: ColorConstant.moyoOrange.withOpacity(
                                  0.3,
                                ),
                              ),
                      ),
                    ),
                    // Badge for billing type
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstant.moyoOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subcategory.billingType.toUpperCase(),
                          style: GoogleFonts.roboto(
                            textStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      subcategory.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.black,
                              height: 1.2,
                            ),
                      ),
                    ),

                    // Price and Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starting from',
                                style: GoogleFonts.roboto(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 9,
                                      ),
                                ),
                              ),
                              Text(
                                '₹${subcategory.hourlyRate}/hr',
                                style: GoogleFonts.roboto(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: ColorConstant.moyoOrange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColorConstant.moyoOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
