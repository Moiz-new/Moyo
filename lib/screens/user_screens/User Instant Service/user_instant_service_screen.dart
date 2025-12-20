import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colorConstant/color_constant.dart';
import '../../../providers/user_navigation_provider.dart';
import '../../SubCategory/SubcategoryResponse.dart';
import 'RequestBroadcastScreen.dart';
import 'UserInstantServiceProvider.dart';
import 'UserLocationPickerScreen.dart';

class UserInstantServiceScreen extends StatefulWidget {
  final int categoryId;
  final String? subcategoryName;
  final String? categoryName;
  final String? serviceType;

  const UserInstantServiceScreen({
    super.key,
    required this.categoryId,
    this.subcategoryName,
    this.categoryName,
    this.serviceType,
  });

  @override
  State<UserInstantServiceScreen> createState() =>
      _UserInstantServiceScreenState();
}

class _UserInstantServiceScreenState extends State<UserInstantServiceScreen> {
  bool _isInitialized = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // ✅ FIX: Separate initialization method
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    final provider = context.read<UserInstantServiceProvider>();

    // Reset provider state first
    provider.reset();

    // Fetch subcategories
    await provider.fetchSubcategories(widget.categoryId);

    if (provider.subcategoryResponse != null &&
        provider.subcategoryResponse!.subcategories.isNotEmpty) {
      Subcategory? subcategoryToSelect;

      if (widget.subcategoryName != null) {
        try {
          subcategoryToSelect = provider.subcategoryResponse!.subcategories
              .firstWhere(
                (sub) => sub.name == widget.subcategoryName,
                orElse: () => provider.subcategoryResponse!.subcategories.first,
              );
        } catch (e) {
          subcategoryToSelect =
              provider.subcategoryResponse!.subcategories.first;
        }
      } else {
        subcategoryToSelect = provider.subcategoryResponse!.subcategories.first;
      }

      // ✅ FIX: Use the new method that doesn't trigger notifyListeners
      provider.setSelectedSubcategoryInitial(subcategoryToSelect);
    }

    // Get location
    await provider.getCurrentLocation();

    _isInitialized = true;
  }

  @override
  void didUpdateWidget(UserInstantServiceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ FIX: Reset when category changes
    if (oldWidget.categoryId != widget.categoryId) {
      _isInitialized = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeScreen();
      });
    }
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
                      _isInitialized = false;
                      _initializeScreen();
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

          if (provider.selectedSubcategory == null) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
            );
          }

          final selectedSubcategory = provider.selectedSubcategory!;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 16,
                    children: [
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
                      _locationPickerField(context),

                      if (selectedSubcategory.billingType.toLowerCase() ==
                          'time')
                        _timeBillingFields(context, selectedSubcategory),

                      if (widget.serviceType == 'later')
                        _projectBillingFields(context),

                      _budgetTextField(context),
                      _paymentMethodField(context),

                      if (selectedSubcategory.billingType.toLowerCase() ==
                          'time')
                        _tenureField(context),

                      //_preRequisiteIncludesExcludes(context),
                      _preRequisiteItems(context, selectedSubcategory),

                      _findServiceproviders(
                        context,
                        onPress: () async {
                          // ✅ First check if payment method is selected before showing all validation errors
                          final selectedMethod = provider.getFormValue('payment_method');

                          if (selectedMethod == null || selectedMethod.toString().isEmpty) {
                            // Show specific payment method error without triggering all validations
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a payment method'),
                                backgroundColor: Colors.red,
                              ),
                            );

                            // Now trigger validation display for visual feedback
                            setState(() {
                              _showValidationErrors = true;
                            });
                            return; // Stop here, don't proceed with form submission
                          }

                          // ✅ Trigger validation display for other fields
                          setState(() {
                            _showValidationErrors = true;
                          });

                          if (provider.validateForm(serviceType: widget.serviceType)) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstant.moyoOrange,
                                ),
                              ),
                            );

                            // ✅ Get the result with service ID, latitude, and longitude
                            final result = await provider.createService(
                              categoryName: widget.categoryName ?? 'General',
                              subcategoryName: selectedSubcategory.name,
                              billingtype: selectedSubcategory.billingType,
                              serviceType: widget.serviceType,
                            );

                            Navigator.pop(context);

                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getInt('user_id');

                            if (result['success'] == true) {
                              final serviceId = result['serviceId']; // ✅ Extract service ID
                              final latitude = result['latitude']; // ✅ Extract latitude
                              final longitude = result['longitude']; // ✅ Extract longitude

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RequestBroadcastScreen(
                                    userId: userId,
                                    serviceId: serviceId, // ✅ Pass service ID
                                    latitude: latitude, // ✅ Pass latitude
                                    longitude: longitude, // ✅ Pass longitude
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.error ?? 'Required fields are missing',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.getValidationError(
                                    serviceType: widget.serviceType,
                                  ) ??
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

  Widget _budgetTextField(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        final budgetValue = provider.getFormValue('budget')?.toString() ?? '';
        final errorText = budgetValue.isNotEmpty
            ? provider.validateBudget(budgetValue)
            : null;

        return Column(
          spacing: 6,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Your Budget",
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
            TextField(
              key: ValueKey('budget_${provider.selectedSubcategory?.id}'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: budgetValue)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: budgetValue.length),
                ),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 18,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFFFFFFF),
                alignLabelWithHint: true,
                hintText: provider.getBudgetHint(),
                hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.currency_rupee),
                errorText: errorText,
                errorMaxLines: 2,
                errorStyle: TextStyle(fontSize: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : ColorConstant.moyoOrange.withAlpha(0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : ColorConstant.moyoOrange,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              maxLines: 1,
              onChanged: (value) {
                provider.updateFormValue('budget', value);
              },
            ),
            if (provider.getBudgetRange() != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Base amount: ₹${provider.getBudgetRange()!['base']!.toStringAsFixed(0)} | Range: ₹${provider.getBudgetRange()!['min']!.toStringAsFixed(0)} - ₹${provider.getBudgetRange()!['max']!.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _locationPickerField(BuildContext context) {
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
                    "Service Location",
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
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserLocationPickerScreen(
                      initialLatitude: provider.latitude,
                      initialLongitude: provider.longitude,
                    ),
                  ),
                );

                if (result != null) {
                  provider.setLocation(
                    result['latitude'],
                    result['longitude'],
                    result['address'],
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.location != null
                        ? ColorConstant.moyoOrange
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: ColorConstant.moyoOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.location ?? 'Tap to select location',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: provider.location != null
                                  ? Colors.black
                                  : Color(0xFF686868),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _timeBillingFields(BuildContext context, Subcategory subcategory) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        final selectedMode = provider.selectedServiceMode;

        return Column(
          spacing: 16,
          children: [
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
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => provider.setServiceMode('hrs'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedMode == 'hrs'
                                  ? ColorConstant.moyoOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Hourly',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: selectedMode == 'hrs'
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: selectedMode == 'hrs'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => provider.setServiceMode('day'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedMode == 'day'
                                  ? ColorConstant.moyoOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Daily',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: selectedMode == 'day'
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: selectedMode == 'day'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (selectedMode == 'hrs') ...[
              _durationFields(context),
              if (widget.serviceType != 'instant')
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
        final currentDays = provider.serviceDays?.toString() ?? '';

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
                key: ValueKey(
                  'service_days_${provider.selectedSubcategory?.id}',
                ),
                controller: TextEditingController(text: currentDays)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: currentDays.length),
                  ),
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
            GestureDetector(
              onTap: () => _selectDate(
                context,
                provider.startDate ?? DateTime.now(),
                (picked) => provider.setStartDate(picked),
              ),
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
                      border: Border.all(
                        color: provider.startDate != null
                            ? ColorConstant.moyoOrange
                            : Colors.grey.shade300,
                      ),
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

  void _selectDate(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: ColorConstant.moyoOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  Widget _paymentMethodField(BuildContext context) {
    return Consumer<UserInstantServiceProvider>(
      builder: (context, provider, child) {
        final selectedMethod = provider.getFormValue('payment_method');

        // ✅ Only show error when user clicks submit button
        final hasError =
            _showValidationErrors &&
            (selectedMethod == null || selectedMethod.toString().isEmpty);

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
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                // ✅ Red border only after validation attempt
                border: hasError
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        provider.updateFormValue('payment_method', 'online');
                        setState(() {
                          _showValidationErrors = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'online'
                              ? ColorConstant.moyoOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              color: selectedMethod == 'online'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pay Online',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: selectedMethod == 'online'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: selectedMethod == 'online'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        provider.updateFormValue('payment_method', 'cash');
                        // ✅ Clear error when user selects
                        setState(() {
                          _showValidationErrors = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'cash'
                              ? ColorConstant.moyoOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.money,
                              color: selectedMethod == 'cash'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cash',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: selectedMethod == 'cash'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: selectedMethod == 'cash'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
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

            // ✅ Show error only when validation triggered and method not selected
            if (hasError)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Please select a payment method',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),

            // Cash warning container
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
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: ColorConstant.moyoOrange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The cash mode can only be limited upto 2000rs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorConstant.moyoOrange,
                          fontWeight: FontWeight.w500,
                        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with required indicator
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
        SizedBox(height: 6),

        // Dropdown Field
        Consumer<UserInstantServiceProvider>(
          builder: (context, provider, child) {
            final currentValue = provider.getFormValue(fieldName ?? '');

            // ✅ FIX: Clean and validate options list
            final cleanOptions =
                options
                    ?.where((value) => value.trim().isNotEmpty)
                    .map((e) => e.trim())
                    .toList() ??
                [];

            // ✅ FIX: Only use currentValue if it exists in options
            final validValue = cleanOptions.contains(currentValue)
                ? currentValue
                : null;

            return DropdownButtonFormField<String>(
              value: validValue,
              isExpanded: true,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 18,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFFFFFFF),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintText: 'Select an option...',
                hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: ColorConstant.moyoOrange,
              ),
              // ✅ FIX: Handle empty options list
              items: cleanOptions.isEmpty
                  ? [
                      DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('No options available'),
                      ),
                    ]
                  : cleanOptions.map((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
              onChanged: cleanOptions.isEmpty
                  ? null
                  : (value) {
                      if (fieldName != null && value != null) {
                        provider.updateFormValue(fieldName, value);
                      }
                    },
              validator: isRequired
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an option';
                      }
                      return null;
                    }
                  : null,
            );
          },
        ),
      ],
    );
  }

  /* Widget _preRequisiteIncludesExcludes(BuildContext context) {
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
  }*/

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
                      items: ['hour'].map((String value) {
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
    if (widget.serviceType == 'instant') {
      return SizedBox.shrink();
    }
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

  Widget _preRequisiteItems(BuildContext context, Subcategory subcategory) {
    // Create local non-nullable copies
    final explicitSiteList = subcategory.explicitSite;
    final implicitSiteList = subcategory.implicitSite;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show explicit site section only if data exists
          if (explicitSiteList!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                Expanded(
                  child: Text(
                    "Provider Brings",
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: ColorConstant.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildEquipmentRowExplicit(context, explicitSiteList),
            SizedBox(height: 16),
          ],

          // Show implicit site section only if data exists
          if (implicitSiteList!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                Expanded(
                  child: Text(
                    "Customer Provides",
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: ColorConstant.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildEquipmentRowImplicit(context, implicitSiteList!),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentRowExplicit(
    BuildContext context,
    List<ExplicitSite> items,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: items
          .map((item) => _buildEquipmentItem(context, item.name, item.image!))
          .toList(),
    );
  }

  Widget _buildEquipmentRowImplicit(
    BuildContext context,
    List<ImplicitSite> items,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: items
          .map((item) => _buildEquipmentItem(context, item.name, item.image!))
          .toList(),
    );
  }

  Widget _buildEquipmentItem(
    BuildContext context,
    String label,
    String imageUrl,
  ) {
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
            imageUrl: imageUrl.isNotEmpty
                ? imageUrl
                : "https://picsum.photos/200/200",
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Image.asset('assets/images/moyo_image_placeholder.png'),
            errorWidget: (context, url, error) =>
                Image.asset('assets/images/moyo_image_placeholder.png'),
          ),
        ),
        Container(
          width: 60,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(color: ColorConstant.black),
          ),
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
