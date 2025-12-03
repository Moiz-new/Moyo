import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'SkillProvider.dart';
import 'SubcategoryResponse.dart';

class SubcategoryDetailsScreen extends StatefulWidget {
  final Subcategory subcategory;
  final String? imageUrl;
  final String serviceName;

  const SubcategoryDetailsScreen({
    super.key,
    required this.subcategory,
    this.imageUrl,
    required this.serviceName,
  });

  @override
  State<SubcategoryDetailsScreen> createState() =>
      _SubcategoryDetailsScreenState();
}

class _SubcategoryDetailsScreenState extends State<SubcategoryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  File? _proofDocument;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _proofDocument = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
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
        title: Text(
          widget.subcategory.name,
          style: GoogleFonts.roboto(
            textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ColorConstant.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPricingCard(),
                    SizedBox(height: 16),
                    _buildDetailsCard(),
                    SizedBox(height: 16),
                    _buildExperienceCard(),
                    SizedBox(height: 16),
                    _buildDocumentUploadCard(),
                    SizedBox(height: 16),
                    if (widget.subcategory.explicitSite != null &&
                        widget.subcategory.explicitSite!.isNotEmpty)
                      _buildSitesSection(
                        'Explicit Sites',
                        widget.subcategory.explicitSite!,
                      ),
                    if (widget.subcategory.implicitSite != null &&
                        widget.subcategory.implicitSite!.isNotEmpty)
                      _buildSitesSection(
                        'Implicit Sites',
                        widget.subcategory.implicitSite!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(color: Color(0xFFF7E5D1)),
      child: Stack(
        children: [
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: ColorConstant.moyoOrange,
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.room_service_outlined,
                  size: 80,
                  color: ColorConstant.moyoOrange.withOpacity(0.3),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                Icons.room_service_outlined,
                size: 80,
                color: ColorConstant.moyoOrange.withOpacity(0.3),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.subcategory.billingType.toUpperCase(),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorConstant.black,
            ),
          ),
          SizedBox(height: 16),
          _buildPriceRow('Hourly Rate', widget.subcategory.hourlyRate),
          _buildPriceRow('Daily Rate', widget.subcategory.dailyRate),
          _buildPriceRow('Weekly Rate', widget.subcategory.weeklyRate),
          _buildPriceRow('Monthly Rate', widget.subcategory.monthlyRate),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            '₹$price',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorConstant.moyoOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorConstant.black,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('GST', '${widget.subcategory.gst}%'),
          _buildDetailRow('TDS', '${widget.subcategory.tds}%'),
          _buildDetailRow('Commission', '${widget.subcategory.commission}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstant.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work_outline,
                color: ColorConstant.moyoOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Experience',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstant.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter years of experience',
              hintStyle: GoogleFonts.roboto(color: Colors.grey[400]),
              suffixText: 'years',
              suffixStyle: GoogleFonts.roboto(
                color: ColorConstant.moyoOrange,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: ColorConstant.scaffoldGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ColorConstant.moyoOrange,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your experience';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: ColorConstant.moyoOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Proof Document',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstant.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Upload a certificate or proof of your expertise',
            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: _pickDocument,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _proofDocument != null
                    ? Colors.green.withOpacity(0.05)
                    : ColorConstant.scaffoldGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proofDocument != null
                      ? Colors.green.withOpacity(0.5)
                      : ColorConstant.moyoOrange.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _proofDocument != null
                          ? Colors.green.withOpacity(0.1)
                          : ColorConstant.moyoOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _proofDocument != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      color: _proofDocument != null
                          ? Colors.green
                          : ColorConstant.moyoOrange,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _proofDocument != null
                              ? 'Document Uploaded'
                              : 'Upload Proof Document',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _proofDocument != null
                              ? _proofDocument!.path.split('/').last
                              : 'Tap to select from gallery',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_proofDocument != null)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _proofDocument = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSitesSection(String title, List<dynamic> sites) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorConstant.black,
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              final siteName = site is ExplicitSite
                  ? site.name
                  : (site is ImplicitSite ? site.name : '');
              final siteImage = site is ExplicitSite
                  ? site.image
                  : (site is ImplicitSite ? site.image : null);

              return _buildSiteCard(siteName, siteImage);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(String siteName, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstant.moyoOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.moyoOrange.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: ColorConstant.moyoOrange,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.location_city,
                        size: 30,
                        color: ColorConstant.moyoOrange.withOpacity(0.5),
                      ),
                    )
                  : Icon(
                      Icons.location_city,
                      size: 30,
                      color: ColorConstant.moyoOrange.withOpacity(0.5),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              siteName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ColorConstant.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<SkillProvider>(
      builder: (context, skillProvider, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: skillProvider.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: skillProvider.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Submitting...',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Submit Skill',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Please fill all required fields correctly');
      return;
    }

    _formKey.currentState?.save();

    final skillProvider = Provider.of<SkillProvider>(context, listen: false);

    final response = await skillProvider.addSkill(
      skillName: widget.subcategory.name,
      serviceName: widget.serviceName,
      experience: _experienceController.text,
      proofDocument: _proofDocument,
    );

    if (response != null) {
      _showSuccessDialog(response);
    } else {
      _showErrorSnackBar(
        skillProvider.errorMessage ??
            'Failed to submit skill. Please try again.',
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Animation Container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 50),
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'Skill Submitted!',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ColorConstant.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Message
              Text(
                response['message'] ??
                    'Your skill has been successfully submitted',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Status Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstant.moyoOrange.withOpacity(0.1),
                      ColorConstant.moyoOrange.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorConstant.moyoOrange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pending_outlined,
                          color: ColorConstant.moyoOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Status: ${response['status'] ?? 'Pending'}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your skill is under verification',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We\'ll notify you once it\'s approved',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
