import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colorConstant/color_constant.dart';


class BankVerifyScreen extends StatefulWidget {
  @override
  _BankVerifyScreenState createState() => _BankVerifyScreenState();
}

class _BankVerifyScreenState extends State<BankVerifyScreen> {
  bool isLoading = false;
  bool accountExists = false;
  String? fullName, upiId, remarks;
  Map<String, dynamic>? ifscDetails;
  String errorMessage = '';

  // Form controllers
  final TextEditingController accountController = TextEditingController(text: "123456789000001");
  final TextEditingController ifscController = TextEditingController(text: "SBIN0000001");

  @override
  void initState() {
    super.initState();
    // Show form first, don't auto-verify
    isLoading = false;
  }

  Future<void> _verifyBankAccount() async {
    if (accountController.text.isEmpty || ifscController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter both account number and IFSC code';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          errorMessage = 'Please login first';
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.moyointernational.com/api/auth/bank-verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "account_number": accountController.text.trim(),
          "ifsc_code": ifscController.text.trim().toUpperCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          accountExists = data['data']['account_exists'] ?? false;
          fullName = data['data']['full_name'];
          upiId = data['data']['upi_id'];
          remarks = data['data']['remarks'] ?? '';
          ifscDetails = data['data']['ifsc_details'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Verification failed: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorConstant.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value.isEmpty ? 'Not available' : value,
            style: TextStyle(
              fontSize: 16.sp,
              color: ColorConstant.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isCaps) {
    return TextField(
      controller: controller,
      textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: TextInputType.text,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp, color: ColorConstant.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: ColorConstant.moyoOrangeFade.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: ColorConstant.moyoOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: AppBar(
        title: Text(
          'Bank Verification',
          style: TextStyle(
            color: ColorConstant.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ColorConstant.moyoOrange,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorConstant.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorConstant.moyoScaffoldGradient,
              ColorConstant.moyoScaffoldGradientLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : fullName == null
                      ? _buildFormState()
                      : _buildSuccessState(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorConstant.moyoOrange,
            strokeWidth: 3.sp,
          ),
          SizedBox(height: 20.h),
          Text(
            'Verifying bank account...',
            style: TextStyle(
              fontSize: 16.sp,
              color: ColorConstant.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 16.sp,
              color: ColorConstant.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                errorMessage = '';
                accountController.clear();
                ifscController.clear();
                accountController.text = "123456789000001";
                ifscController.text = "SBIN0000001";
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.moyoOrange,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Text(
              'Try Again',
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: ColorConstant.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: ColorConstant.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 64.sp,
                  color: ColorConstant.moyoOrange,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Verify Bank Account',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.onSurface,
                  ),
                ),
                Text(
                  'Enter your bank details to verify',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: ColorConstant.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 32.h),
                _buildTextField('Account Number', accountController, false),
                SizedBox(height: 20.h),
                _buildTextField('IFSC Code', ifscController, true),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _verifyBankAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Verify Account',
                      style: TextStyle(
                        color: ColorConstant.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildSuccessState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: accountExists
                    ? [ColorConstant.moyoGreen.withOpacity(0.15), Colors.transparent]
                    : [ColorConstant.moyoOrangeFade, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: accountExists ? ColorConstant.moyoGreen : ColorConstant.moyoOrange,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: accountExists ? ColorConstant.moyoGreen : ColorConstant.moyoOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accountExists ? Icons.verified : Icons.account_balance_wallet_outlined,
                    color: ColorConstant.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountExists ? 'Bank Account Verified' : 'Account Detected',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: accountExists ? ColorConstant.moyoGreen : ColorConstant.moyoOrange,
                        ),
                      ),
                      Text(
                        'Your bank details are linked successfully',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorConstant.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Cards
          _buildInfoCard('Full Name', fullName ?? 'N/A'),
          SizedBox(height: 16.h),
          _buildInfoCard('UPI ID', upiId ?? 'Not linked'),
          SizedBox(height: 16.h),
          _buildInfoCard('Remarks', remarks?.isNotEmpty == true ? remarks! : 'None'),
          SizedBox(height: 16.h),
          _buildInfoCard(
            'IFSC Details',
            ifscDetails != null && ifscDetails!.isNotEmpty
                ? ifscDetails.toString()
                : 'Not available',
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  @override
  void dispose() {
    accountController.dispose();
    ifscController.dispose();
    super.dispose();
  }
}
