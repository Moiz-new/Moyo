import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colorConstant/color_constant.dart';
import 'PaymentBudgetProvider.dart';

class PaymentOptionsScreen extends StatefulWidget {
  final double totalAmount;
  final String categoryName;
  final String subcategoryName;
  final String serviceId;
  final Function(Map<String, dynamic>)? onPaymentComplete;

  const PaymentOptionsScreen({
    super.key,
    required this.totalAmount,
    required this.categoryName,
    required this.subcategoryName,
    required this.serviceId,
    this.onPaymentComplete,
  });

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  String? selectedPaymentType;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPaymentBudget();
    });
  }

  Future<void> _fetchPaymentBudget() async {
    final provider = Provider.of<PaymentBudgetProvider>(context, listen: false);
    await provider.fetchPaymentBudget(widget.serviceId, widget.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        backgroundColor: ColorConstant.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorConstant.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Options',
          style: GoogleFonts.roboto(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: ColorConstant.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<PaymentBudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConstant.moyoOrange),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading payment options...',
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: Colors.red.shade400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load payment options',
                      style: GoogleFonts.roboto(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      provider.error!,
                      style: GoogleFonts.roboto(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: _fetchPaymentBudget,
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.moyoOrange,
                        foregroundColor: ColorConstant.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.paymentBudget == null) {
            return Center(
              child: Text(
                'No payment data available',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          final budget = provider.paymentBudget!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Service Summary Card
                Container(
                  margin: EdgeInsets.all(16.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstant.moyoOrange,
                        ColorConstant.moyoScaffoldGradient,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstant.moyoOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: ColorConstant.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Service Summary',
                            style: GoogleFonts.roboto(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildSummaryRow('Category', widget.categoryName),
                      SizedBox(height: 8.h),
                      _buildSummaryRow('Service', budget.title),
                      SizedBox(height: 8.h),
                      _buildSummaryRow(
                        'Duration',
                        '${budget.serviceDays} days',
                      ),
                      SizedBox(height: 8.h),
                      if (budget.perDayBidAmount > 0)
                        _buildSummaryRow(
                          'Per Day',
                          '₹${budget.perDayBidAmount.toStringAsFixed(0)}',
                        ),
                      SizedBox(height: 8.h),
                      Divider(color: ColorConstant.white.withOpacity(0.3)),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.roboto(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: ColorConstant.white,
                            ),
                          ),
                          Text(
                            '₹${budget.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: ColorConstant.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Payment Options Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose Your Payment Plan',
                      style: GoogleFonts.roboto(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.black,
                      ),
                    ),
                  ),
                ),

                // Payment Cards
                if (budget.allowPartPayment && budget.payments.partPayment > 0)
                  _buildPaymentCard(
                    type: 'one_day',
                    title: 'One Day Payment',
                    subtitle: 'Pay for single day service',
                    amount: budget.payments.partPayment,
                    icon: Icons.today,
                    recommended: false,
                  ),

                _buildPaymentCard(
                  type: 'partial',
                  title: 'Half Payment',
                  subtitle: 'Pay 50% now, rest after service',
                  amount: budget.payments.halfPayment,
                  icon: Icons.pie_chart,
                  recommended: true,
                ),

                _buildPaymentCard(
                  type: 'full',
                  title: 'Full Payment',
                  subtitle: 'Pay complete amount upfront',
                  amount: budget.payments.fullPayment,
                  icon: Icons.payments,
                  recommended: false,
                  discount: budget.payments.fullPayment < budget.totalAmount
                      ? ((1 - budget.payments.fullPayment / budget.totalAmount) * 100).toInt()
                      : null,
                ),

                // Note
                if (budget.note.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              budget.note,
                              style: GoogleFonts.roboto(
                                fontSize: 12.sp,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 20.h),

                // Proceed Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ElevatedButton(
                    onPressed: (selectedPaymentType != null && !_isProcessingPayment)
                        ? () {
                      _handlePaymentProceed(budget);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: selectedPaymentType != null ? 4 : 0,
                    ),
                    child: _isProcessingPayment
                        ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        color: ColorConstant.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          color: ColorConstant.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Proceed to Payment',
                          style: GoogleFonts.roboto(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Security Info
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: ColorConstant.moyoGreen,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '100% Secure Payment',
                        style: GoogleFonts.roboto(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14.sp,
            color: ColorConstant.white.withOpacity(0.9),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: ColorConstant.white,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String type,
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    bool recommended = false,
    int? discount,
  }) {
    final isSelected = selectedPaymentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentType = type;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ColorConstant.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? ColorConstant.moyoOrange : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: ColorConstant.moyoOrange.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (recommended)
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorConstant.moyoGreen,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: GoogleFonts.roboto(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: ColorConstant.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            if (discount != null && discount > 0)
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorConstant.moyoOrange,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: GoogleFonts.roboto(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: ColorConstant.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    height: 60.w,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstant.moyoOrange.withOpacity(0.1)
                          : ColorConstant.moyoOrangeFade,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: ColorConstant.moyoOrange,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: GoogleFonts.roboto(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: GoogleFonts.roboto(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24.w,
                    width: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? ColorConstant.moyoOrange
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                      child: Container(
                        height: 14.w,
                        width: 14.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstant.moyoOrange,
                        ),
                      ),
                    )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentProceed(PaymentBudgetModel budget) async {
    if (selectedPaymentType == null) return;

    double payableAmount = budget.totalAmount;

    if (selectedPaymentType == 'one_day') {
      payableAmount = budget.payments.partPayment;
    } else if (selectedPaymentType == 'partial') {
      payableAmount = budget.payments.halfPayment;
    } else if (selectedPaymentType == 'full') {
      payableAmount = budget.payments.fullPayment;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'User';
      final userEmail = prefs.getString('user_email') ?? 'user@example.com';
      final userPhone = prefs.getString('user_phone') ?? '9999999999';

      final provider = Provider.of<PaymentBudgetProvider>(
        context,
        listen: false,
      );

      await provider.openCheckout(
        serviceId: widget.serviceId,
        amount: payableAmount,
        paymentType: selectedPaymentType!,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        onSuccess: (paymentData) async {
          // Verify payment


          setState(() {
            _isProcessingPayment = false;
          });

            Navigator.pop(context, {
              'payment_type': selectedPaymentType,
              'amount': payableAmount,
              'total_amount': budget.totalAmount,
              'service_days': budget.serviceDays,
              'per_day_amount': budget.perDayBidAmount,
              'payment_id': paymentData['payment_id'],
              'order_id': paymentData['order_id'],
              'status': 'success',
            });

        },
        onError: (error) {
          setState(() {
            _isProcessingPayment = false;
          });
          _showErrorDialog(error);
        },
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      _showErrorDialog('Failed to initiate payment: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8.w),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeName(String type) {
    switch (type) {
      case 'one_day':
        return 'One Day Payment';
      case 'partial':
        return 'Half Payment';
      case 'full':
        return 'Full Payment';
      default:
        return '';
    }
  }
}