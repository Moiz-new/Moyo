import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

import 'SubcategoryProvider.dart';
import 'SkillProvider.dart';

class SelectFromHomeScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;

  const SelectFromHomeScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
  });

  @override
  State<SelectFromHomeScreen> createState() => _SelectFromHomeScreenState();
}

class _SelectFromHomeScreenState extends State<SelectFromHomeScreen> {
  Map<int, bool> selectedSubcategories = {};
  Map<int, String> experienceYears = {};
  Map<int, File?> attachments = {};
  int? expandedCardIndex;

  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubcategoryProvider>().fetchSubcategories(widget.categoryId);
    });
  }

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > maxFileSizeBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File size exceeds 5MB limit. Please select a smaller file.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          attachments[index] = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  String _getFileName(File? file) {
    if (file == null) return '';
    return file.path.split('/').last;
  }

  String _getFileSize(File? file) {
    if (file == null) return '';
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    final isNearLimit = bytes > (maxFileSizeBytes * 0.9);
    final sizeText = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return isNearLimit ? '⚠️ $sizeText (Max: 5MB)' : sizeText;
  }

  Future<void> _showUncheckDialog(int skillId, String skillName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uncheck Skill?',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to uncheck "$skillName"? This will mark it as not selected.',
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _uncheckSkill(skillId, skillName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uncheckSkill(int skillId, String skillName) async {
    final subcategoryProvider = context.read<SubcategoryProvider>();
    final result = await subcategoryProvider.uncheckSkill(skillId);

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$skillName unchecked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subcategoryProvider.errorMessage ?? 'Failed to uncheck skill',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitSkill(int index, dynamic subcategory) async {
    if (!selectedSubcategories[index]!) return;

    final experience = experienceYears[index];
    if (experience == null || experience.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter years of experience'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final attachment = attachments[index];
    if (attachment != null) {
      final fileSize = attachment.lengthSync();
      if (fileSize > maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File size exceeds 5MB limit. Please select a smaller file.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final skillProvider = context.read<SkillProvider>();

    final result = await skillProvider.addSkill(
      skillName: subcategory.name,
      serviceName: widget.categoryName,
      experience: experience,
      proofDocument: attachment,
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skill added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        selectedSubcategories[index] = false;
        experienceYears[index] = "";
        attachments[index] = null;
        expandedCardIndex = null;
      });
    } else if (skillProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(skillProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSiteSection(
    String title,
    List<dynamic>? sites,
    SubcategoryProvider provider,
  ) {
    if (sites == null || sites.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstant.black,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sites.map((site) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConstant.moyoOrange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (site.image != null && site.image!.isNotEmpty)
                    Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: provider.getFullImageUrl(site.image),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.image,
                            size: 16,
                            color: ColorConstant.moyoOrange,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image,
                            size: 16,
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    site.name,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        backgroundColor: ColorConstant.moyoOrange,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select from ${widget.categoryName}',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer2<SubcategoryProvider, SkillProvider>(
        builder: (context, subcategoryProvider, skillProvider, child) {
          if (subcategoryProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
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
                      subcategoryProvider.errorMessage ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 16),
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (subcategoryProvider.subcategories.isEmpty) {
            return Center(
              child: Text(
                'No subcategories available',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: subcategoryProvider.subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategoryProvider.subcategories[index];
              final isSelected = selectedSubcategories[index] ?? false;
              final isExpanded = expandedCardIndex == index;
              final isAlreadyChecked = subcategory.isSubcategory;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: isAlreadyChecked
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected && isExpanded) {
                                    expandedCardIndex = null;
                                  } else if (isSelected && !isExpanded) {
                                    expandedCardIndex = index;
                                  } else {
                                    selectedSubcategories[index] = true;
                                    expandedCardIndex = index;
                                  }
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFF4E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child:
                                      subcategory.icon != null &&
                                          subcategory.icon!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: context
                                              .read<SubcategoryProvider>()
                                              .getFullImageUrl(
                                                subcategory.icon,
                                              ),
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Icon(
                                            Icons.restaurant,
                                            color: ColorConstant.moyoOrange,
                                            size: 30,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.restaurant,
                                                color: ColorConstant.moyoOrange,
                                                size: 30,
                                              ),
                                        )
                                      : Icon(
                                          Icons.restaurant,
                                          color: ColorConstant.moyoOrange,
                                          size: 30,
                                        ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  subcategory.name,
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: ColorConstant.black,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: isAlreadyChecked
                                    ? () {
                                        _showUncheckDialog(
                                          subcategory.id,
                                          subcategory.name,
                                        );
                                      }
                                    : () {
                                        setState(() {
                                          selectedSubcategories[index] =
                                              !isSelected;
                                          if (!isSelected) {
                                            expandedCardIndex = index;
                                          } else {
                                            expandedCardIndex = null;
                                            experienceYears[index] = "";
                                            attachments[index] = null;
                                          }
                                        });
                                      },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isAlreadyChecked
                                        ? Colors.green
                                        : isSelected
                                        ? ColorConstant.moyoOrange
                                        : Colors.white,
                                    border: Border.all(
                                      color: isAlreadyChecked
                                          ? Colors.green
                                          : isSelected
                                          ? ColorConstant.moyoOrange
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: (isAlreadyChecked || isSelected)
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(height: 1),
                              SizedBox(height: 16),
                              Text(
                                'Year Of Experience',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.work_outline,
                                        color: Colors.grey[700],
                                        size: 24,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: '0',
                                          hintStyle: GoogleFonts.roboto(
                                            fontSize: 18,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        style: GoogleFonts.roboto(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        onChanged: (value) {
                                          experienceYears[index] = value;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              InkWell(
                                onTap: () => _pickFile(index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        color: ColorConstant.black,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Add Attachment',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: ColorConstant.black,
                                            ),
                                          ),
                                          Text(
                                            'PDF, PNG, JPG, JPEG • Max 5MB',
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (attachments[index] != null) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF4E6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ColorConstant.moyoOrange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.description,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getFileName(attachments[index]),
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _getFileSize(attachments[index]),
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            attachments[index] = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ✅ Display Explicit Sites
                              _buildSiteSection(
                                'Provider brings',
                                subcategory.explicitSite,
                                subcategoryProvider,
                              ),

                              // ✅ Display Implicit Sites
                              _buildSiteSection(
                                'Customer Provides',
                                subcategory.implicitSite,
                                subcategoryProvider,
                              ),

                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: skillProvider.isLoading
                                      ? null
                                      : () => _submitSkill(index, subcategory),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstant.moyoOrange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: skillProvider.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Submit',
                                          style: GoogleFonts.roboto(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
