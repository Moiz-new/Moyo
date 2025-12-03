import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/colorConstant/color_constant.dart';
import '../../../providers/user_navigation_provider.dart';
import '../../SubCategory/SubcategoryResponse.dart';
import 'UserInstantServiceProvider.dart';

class UserInstantServiceScreen extends StatefulWidget {
  final int categoryId;
  final String? subcategoryName;
  final String? categoryName;

  const UserInstantServiceScreen({
    super.key,
    required this.categoryId,
    this.subcategoryName,
    this.categoryName,
  });

  @override
  State<UserInstantServiceScreen> createState() =>
      _UserInstantServiceScreenState();
}

class _UserInstantServiceScreenState extends State<UserInstantServiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserInstantServiceProvider>();
      provider.fetchSubcategories(widget.categoryId);
      provider.getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: UserOnlyTitleAppbar(
        title: widget.subcategoryName ?? "Service Details",
      ),
      body: Consumer<UserInstantServiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
            );
          }

          if (provider.error != null && !provider.isCreatingService) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      provider.error!,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchSubcategories(widget.categoryId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                    ),
                    child: Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (provider.subcategoryResponse == null ||
              provider.subcategoryResponse!.subcategories.isEmpty) {
            return Center(
              child: Text(
                'No subcategories available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          // Find the specific subcategory or use the first one
          Subcategory? selectedSubcategory;
          if (widget.subcategoryName != null) {
            try {
              selectedSubcategory = provider.subcategoryResponse!.subcategories
                  .firstWhere(
                    (sub) => sub.name == widget.subcategoryName,
                    orElse: () =>
                        provider.subcategoryResponse!.subcategories.first,
                  );
            } catch (e) {
              selectedSubcategory =
                  provider.subcategoryResponse!.subcategories.first;
            }
          } else {
            selectedSubcategory =
                provider.subcategoryResponse!.subcategories.first;
          }

          if (provider.selectedSubcategory == null) {
            provider.setSelectedSubcategory(selectedSubcategory);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 16,
                    children: [
                      // Dynamic fields from API
                      if (selectedSubcategory.fields.isNotEmpty)
                        ...selectedSubcategory.fields.map((field) {
                          if (field.fieldType == 'select' &&
                              field.options!.isNotEmpty) {
                            return _moyoDropDownField(
                              context,
                              title: field.fieldName,
                              options: field.options,
                              isRequired: field.isRequired,
                              fieldName: field.fieldName,
                            );
                          } else if (field.fieldType == 'number') {
                            return _moyoTextField(
                              context,
                              title: field.fieldName,
                              isRequired: field.isRequired,
                              fieldName: field.fieldName,
                              keyboardType: TextInputType.number,
                            );
                          } else if (field.fieldType == 'text') {
                            return _moyoTextField(
                              context,
                              title: field.fieldName,
                              isRequired: field.isRequired,
                              fieldName: field.fieldName,
                            );
                          }
                          return SizedBox.shrink();
                        }).toList(),

                      // Conditional fields based on billing type
                      if (selectedSubcategory.billingType.toLowerCase() ==
                          'time')
                        _timeBillingFields(context, selectedSubcategory),

                      if (selectedSubcategory.billingType.toLowerCase() ==
                          'project')
                        _projectBillingFields(context),

                      // Budget field (common for all types)
                      _moyoTextField(
                        context,
                        title: "Your Budget",
                        hint:
                            "Minimum Service Price is ₹ ${selectedSubcategory.hourlyRate}",
                        icon: Icon(Icons.currency_rupee),
                        keyboardType: TextInputType.number,
                        fieldName: "budget",
                        isRequired: true,
                      ),

                      // Payment method (common for all types)
                      _paymentMethodField(context),

                      // Only show tenure for time billing
                      if (selectedSubcategory.billingType.toLowerCase() ==
                          'time')
                        _tenureField(context),

                      // Pre-requisites (common for all types)
                      _preRequisiteIncludesExcludes(context),
                      _preRequisiteItems(context),

                      // Find service providers button
                      _findServiceproviders(
                        context,
                        onPress: () async {
                          if (provider.validateForm()) {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstant.moyoOrange,
                                ),
                              ),
                            );

                            // Create service
                            final success = await provider.createService(
                              categoryName: widget.categoryName ?? 'General',
                              subcategoryName: selectedSubcategory!.name,
                              billingtype: selectedSubcategory.billingType,
                            );

                            // Close loading dialog
                            Navigator.pop(context);

                            if (success) {
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Service created successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Navigate to service providers
                              context
                                      .read<UserNavigationProvider>()
                                      .currentIndex =
                                  2;
                              Navigator.pushNamed(
                                context,
                                '/UserCustomBottomNav',
                              );
                            } else {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.error ??
                                        'Failed to create service',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.getValidationError() ??
                                      'Please fill all required fields',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Loading overlay when creating service
              if (provider.isCreatingService)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: ColorConstant.moyoOrange,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Creating your service...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Add these methods at the end of _UserInstantServiceScreenState class (before the closing brace)

  Widget _timeBillingFields(BuildContext context, Subcategory subcategory) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        final selectedMode = provider.selectedServiceMode ?? 'hrs';

        return Column(
          spacing: 16,
          children: [
            // Service Mode Selection (hrs or day)
            Column(
              spacing: 6,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "Service Mode",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        " *",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            provider.setServiceMode('hrs');
                          },
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'hrs',
                                groupValue: selectedMode,
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setServiceMode(value);
                                  }
                                },
                                activeColor: ColorConstant.moyoOrange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hourly',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            provider.setServiceMode('day');
                          },
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'day',
                                groupValue: selectedMode,
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setServiceMode(value);
                                  }
                                },
                                activeColor: ColorConstant.moyoOrange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Daily',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show fields based on selected mode
            if (selectedMode == 'hrs') ...[
              _durationFields(context),
              _scheduleDateTimeFields(context),
            ] else if (selectedMode == 'day') ...[
              _serviceDaysField(context),
              _startEndDateFields(context),
            ],
          ],
        );
      },
    );
  }

  Widget _projectBillingFields(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a task-based service. No time scheduling required.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceDaysField(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        return Column(
          spacing: 6,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Number of Days",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    " *",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontSize: 18,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  hintText: 'Enter number of days (e.g., 3)',
                  hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Color(0xFF686868),
                    fontWeight: FontWeight.w400,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: ColorConstant.moyoOrange.withAlpha(50),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorConstant.moyoOrange),
                  ),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0) {
                    provider.setServiceDays(days);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _startEndDateFields(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        return Column(
          spacing: 12,
          children: [
            // Start Date
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: provider.startDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorConstant.moyoOrange,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  provider.setStartDate(picked);
                }
              },
              child: Column(
                spacing: 6,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "Start Date",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          " *",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: ColorConstant.moyoOrange,
                        ),
                        SizedBox(width: 12),
                        Text(
                          provider.startDate != null
                              ? '${provider.startDate!.day}/${provider.startDate!.month}/${provider.startDate!.year}'
                              : 'Select Start Date',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: provider.startDate != null
                                    ? Colors.black
                                    : Color(0xFF686868),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // End Date (Auto-calculated)
            Column(
              spacing: 6,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "End Date",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        " (Auto-calculated)",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                        provider.endDate != null
                            ? '${provider.endDate!.day}/${provider.endDate!.month}/${provider.endDate!.year}'
                            : 'Select start date and days first',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _paymentMethodField(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        final selectedMethod =
            provider.getFormValue('payment_method') ?? 'online';

        return Column(
          spacing: 6,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Payment Method",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    " *",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        provider.updateFormValue('payment_method', 'online');
                      },
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'online',
                            groupValue: selectedMethod,
                            onChanged: (value) {
                              if (value != null) {
                                provider.updateFormValue(
                                  'payment_method',
                                  value,
                                );
                              }
                            },
                            activeColor: ColorConstant.moyoOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pay Online',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        provider.updateFormValue('payment_method', 'cash');
                      },
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'cash',
                            groupValue: selectedMethod,
                            onChanged: (value) {
                              if (value != null) {
                                provider.updateFormValue(
                                  'payment_method',
                                  value,
                                );
                              }
                            },
                            activeColor: ColorConstant.moyoOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cash',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedMethod == 'cash')
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstant.moyoOrange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'The cash mode can only be limited upto 2000rs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorConstant.moyoOrange,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _moyoTextField(
    BuildContext context, {
    String? title,
    String? hint,
    Widget? icon,
    bool isRequired = false,
    String? fieldName,
    TextInputType? keyboardType,
  }) {
    return Column(
      spacing: 6,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                title ?? "title",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isRequired)
                Text(
                  " *",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
            ],
          ),
        ),
        Consumer<UserInstantServiceProvider>(
          builder: (context, provider, child) {
            return TextField(
              keyboardType: keyboardType,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 18,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFFFFFFF),
                alignLabelWithHint: true,
                hintText: hint ?? 'Type here...',
                hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: icon,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: ColorConstant.moyoOrange.withAlpha(0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ColorConstant.moyoOrange),
                ),
              ),
              maxLines: 1,
              onChanged: (value) {
                if (fieldName != null) {
                  provider.updateFormValue(fieldName, value);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _moyoDropDownField(
    BuildContext context, {
    String? title,
    List<String>? options,
    bool isRequired = false,
    String? fieldName,
  }) {
    return Column(
      spacing: 6,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                title ?? "title",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isRequired)
                Text(
                  " *",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
            ],
          ),
        ),
        Consumer<UserInstantServiceProvider>(
          builder: (context, provider, child) {
            final currentValue = provider.getFormValue(fieldName ?? '');
            final validValue = options?.contains(currentValue) == true
                ? currentValue
                : null;

            return DropdownButtonFormField<String>(
              value: validValue,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 16,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFFFFFFF),
                alignLabelWithHint: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: ColorConstant.moyoOrange.withAlpha(0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ColorConstant.moyoOrange),
                ),
              ),
              hint: Text(
                'Select an option...',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                ),
              ),
              items:
                  options?.where((value) => value.trim().isNotEmpty).map((
                    String value,
                  ) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value.trim()),
                    );
                  }).toList() ??
                  [],
              onChanged: (value) {
                if (fieldName != null && value != null) {
                  provider.updateFormValue(fieldName, value);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _preRequisiteIncludesExcludes(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.moyoOrange, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              SvgPicture.asset("assets/icons/pre_right.svg"),
              Text(
                "Service Includes",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: ColorConstant.moyoOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          _buildBulletPoint(context, "Bringing their own Kitchen Knife"),
          _buildBulletPoint(
            context,
            "Cleaning the gas stove and kitchen slab after cooking",
          ),
          _buildBulletPoint(context, "Transferring dishes to utensils"),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              SvgPicture.asset("assets/icons/pre_wrong.svg"),
              Text(
                "Service Excludes",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: ColorConstant.moyoOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          _buildBulletPoint(context, "Dishwashing of guest tableware"),
          _buildBulletPoint(context, "Buying Ingredients for cooking"),
          _buildBulletPoint(context, "Serving food to guests"),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text("•", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: ColorConstant.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationFields(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        return Column(
          spacing: 6,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Service Duration",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    " *",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 18,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        hintText: '2',
                        hintStyle: Theme.of(context).textTheme.titleMedium!
                            .copyWith(
                              color: Color(0xFF686868),
                              fontWeight: FontWeight.w400,
                            ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ColorConstant.moyoOrange.withAlpha(50),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        provider.updateFormValue('duration_value', value);
                      },
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: provider.getFormValue('duration_unit') ?? 'hour',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 18,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ColorConstant.moyoOrange.withAlpha(50),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                      items: ['hour', 'day', 'week', 'month'].map((
                        String value,
                      ) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateFormValue('duration_unit', value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tenureField(BuildContext context) {
    return _moyoDropDownField(
      context,
      title: "Service Tenure",
      options: ['one_time', 'weekly', 'monthly'],
      isRequired: true,
      fieldName: "tenure",
    );
  }

  Widget _scheduleDateTimeFields(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        return Column(
          spacing: 12,
          children: [
            // Schedule Date
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: provider.scheduleDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorConstant.moyoOrange,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  provider.setScheduleDate(picked);
                }
              },
              child: Column(
                spacing: 6,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "Schedule Date",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          " *",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: ColorConstant.moyoOrange,
                        ),
                        SizedBox(width: 12),
                        Text(
                          provider.scheduleDate != null
                              ? '${provider.scheduleDate!.day}/${provider.scheduleDate!.month}/${provider.scheduleDate!.year}'
                              : 'Select Date',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: provider.scheduleDate != null
                                    ? Colors.black
                                    : Color(0xFF686868),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Schedule Time
            InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: provider.scheduleTime ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorConstant.moyoOrange,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  provider.setScheduleTime(picked);
                }
              },
              child: Column(
                spacing: 6,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "Schedule Time",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          " *",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: ColorConstant.moyoOrange,
                        ),
                        SizedBox(width: 12),
                        Text(
                          provider.scheduleTime != null
                              ? '${provider.scheduleTime!.hour.toString().padLeft(2, '0')}:${provider.scheduleTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: provider.scheduleTime != null
                                    ? Colors.black
                                    : Color(0xFF686868),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _preRequisiteItems(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              Expanded(
                child: Text(
                  "Equipment service providers are required to obtain",
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: ColorConstant.black),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildEquipmentRow(context, ["Apron", "Knife", "Cap"]),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              Expanded(
                child: Text(
                  "Equipment provided from our side",
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(color: ColorConstant.black),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildEquipmentRow(context, ["Utensils", "Plates", "Spoons"]),
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(BuildContext context, List<String> items) {
    return Row(
      spacing: 16,
      mainAxisAlignment: MainAxisAlignment.start,
      children: items
          .map((item) => _buildEquipmentItem(context, item))
          .toList(),
    );
  }

  Widget _buildEquipmentItem(BuildContext context, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 6,
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
          height: 38,
          width: 33,
          child: CachedNetworkImage(
            imageUrl: "https://picsum.photos/200/200",
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Image.asset('assets/images/moyo_image_placeholder.png'),
            errorWidget: (context, url, error) =>
                Image.asset('assets/images/moyo_image_placeholder.png'),
          ),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: ColorConstant.black),
        ),
      ],
    );
  }

  Widget _findServiceproviders(BuildContext context, {VoidCallback? onPress}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        onTap: onPress,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ColorConstant.moyoOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.search, color: ColorConstant.white),
              Text(
                "Find Service providers",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w500,
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
