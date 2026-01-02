import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/button_large.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../commonOnboarding/loginScreen/MobileVerificationScreen.dart';
import '../../commonOnboarding/otpScreen/EmailVerificationScreen.dart';
import 'EditProfileProvider.dart';
import 'UserProfileProvider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    final editProvider = context.read<EditProfileProvider>();
    final success = await editProvider.fetchProfileFromApi();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.errorMessage ?? 'Failed to load profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _fetchProfile,
          ),
        ),
      );
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        final provider = context.read<EditProfileProvider>();
        final hasImage =
            provider.selectedImage != null ||
            (provider.currentImageUrl != null &&
                provider.currentImageUrl!.isNotEmpty);

        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: ColorConstant.moyoOrange,
                  size: 24.sp,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: ColorConstant.moyoOrange,
                  size: 24.sp,
                ),
                title: Text('Take a Photo', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImageFromCamera();
                },
              ),
              if (hasImage)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    provider.removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    // Only characters allowed, no numbers
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName should contain only characters';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (value.length > 3) {
      return 'Age should be maximum 3 digits';
    }
    if (age < 18) {
      return 'Minimum age should be 18 years';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    // Max 10 digits, no 0 or + sign
    if (value.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    if (value.startsWith('0')) {
      return 'Phone number should not start with 0';
    }
    if (!RegExp(r'^[1-9][0-9]{9}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSave() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all validation errors'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final editProvider = context.read<EditProfileProvider>();

    editProvider.clearError();
    editProvider.clearEmailError();
    editProvider.clearMobileError();

    // Email verification check
    if (editProvider.emailController.text.trim().isNotEmpty) {
      if (editProvider.hasEmailChanged() && !editProvider.isEmailVerified) {
        _showEmailVerificationRequiredDialog();
        return;
      }
    }

    // Mobile verification check
    if (editProvider.mobileController.text.trim().isNotEmpty) {
      if (editProvider.hasMobileChanged() && !editProvider.isMobileVerified) {
        _showMobileVerificationRequiredDialog();
        return;
      }
    }

    final success = await editProvider.updateProfile();

    if (success && mounted) {
      await context.read<UserProfileProvider>().refreshProfile(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editProvider.successMessage ?? 'Profile updated successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (editProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEmailVerificationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: ColorConstant.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 60.sp,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Email Verification Required',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.black,
                  fontSize: 20.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'You have changed your email address. Please verify your new email before saving changes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7A7A7A),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _handleVerifyEmail();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    foregroundColor: ColorConstant.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Verify Email Now',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ColorConstant.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
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

  void _showMobileVerificationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: ColorConstant.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 60.sp,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Mobile Verification Required',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.black,
                  fontSize: 20.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'You have changed your mobile number. Please verify your new mobile before saving changes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7A7A7A),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _handleVerifyMobile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    foregroundColor: ColorConstant.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Verify Mobile Now',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ColorConstant.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
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

  Future<void> _handleVerifyEmail() async {
    final editProvider = context.read<EditProfileProvider>();
    editProvider.clearEmailError();

    // Validate email before sending OTP
    final emailError = _validateEmail(editProvider.emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final otpSent = await editProvider.sendEmailOtp();

    if (otpSent && mounted) {
      final verified = await EmailVerificationDialog.show(context);

      if (verified == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (editProvider.emailErrorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.emailErrorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyMobile() async {
    final editProvider = context.read<EditProfileProvider>();
    editProvider.clearMobileError();

    // Validate mobile before sending OTP
    final mobileError = _validatePhone(editProvider.mobileController.text);
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mobileError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final otpSent = await editProvider.sendMobileOtp();

    if (otpSent && mounted) {
      final verified = await MobileVerificationDialog.show(context);

      if (verified == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mobile verified successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (editProvider.mobileErrorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.mobileErrorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: "Edit Profile"),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<EditProfileProvider>(
        builder: (context, editProvider, child) {
          if (editProvider.isFetchingProfile) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
            );
          }

          if (editProvider.errorMessage != null &&
              editProvider.firstnameController.text.isEmpty &&
              editProvider.lastnameController.text.isEmpty) {
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
                      'Failed to load profile',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      editProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: _fetchProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.moyoOrange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h),
                      _buildProfileImage(editProvider),
                      SizedBox(height: 30.h),
                      _buildForm(editProvider),
                      SizedBox(height: 30.h),
                      ButtonLarge(
                        isIcon: false,
                        label: "Save Changes",
                        backgroundColor: ColorConstant.moyoOrange,
                        labelColor: Colors.white,
                        onTap: editProvider.isLoading ? null : _handleSave,
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              if (editProvider.isLoading ||
                  editProvider.isEmailOtpLoading ||
                  editProvider.isMobileOtpLoading ||
                  editProvider.isEmailOtpVerifying ||
                  editProvider.isMobileOtpVerifying)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorConstant.moyoOrange,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(EditProfileProvider provider) {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(context),
      child: Stack(
        children: [
          Container(
            height: 155.w,
            width: 155.w,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: ColorConstant.moyoOrange.withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: _buildImageContent(provider),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.w),
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(EditProfileProvider provider) {
    if (provider.imageRemoved) {
      return Image.asset(
        'assets/images/moyo_image_placeholder.png',
        fit: BoxFit.cover,
      );
    }
    if (provider.selectedImage != null) {
      return Image.file(provider.selectedImage!, fit: BoxFit.cover);
    } else if (provider.currentImageUrl != null &&
        provider.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: provider.currentImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: ColorConstant.moyoOrange,
            strokeWidth: 2.w,
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/moyo_image_placeholder.png',
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Image.asset(
        'assets/images/moyo_image_placeholder.png',
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildForm(EditProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: provider.firstnameController,
          label: "First Name",
          icon: Icons.person_outline,
          hint: "Enter your first name",
          validator: (value) => _validateName(value, 'First name'),
        ),
        SizedBox(height: 20.h),
        _buildTextField(
          controller: provider.lastnameController,
          label: "Last Name",
          icon: Icons.person_outline,
          hint: "Enter your last name",
          validator: (value) => _validateName(value, 'Last name'),
        ),
        SizedBox(height: 20.h),
        _buildTextField(
          controller: provider.usernameController,
          label: "Username",
          icon: Icons.alternate_email,
          hint: "Enter your username",
          enabled: !provider.isUsernameSet,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            return null;
          },
        ),
        SizedBox(height: 20.h),
        _buildEmailFieldWithVerify(provider),
        SizedBox(height: 20.h),
        _buildMobileFieldWithVerify(provider),
        SizedBox(height: 20.h),
        _buildTextField(
          controller: provider.ageController,
          label: "Age (Minimum 18 years)",
          icon: Icons.cake_outlined,
          hint: "Enter your age",
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          validator: _validateAge,
        ),
        SizedBox(height: 20.h),
        _buildGenderSelector(provider),
      ],
    );
  }

  Widget _buildEmailFieldWithVerify(EditProfileProvider provider) {
    final hasEmailChanged = provider.hasEmailChanged();
    final isVerified = provider.isEmailVerified;
    final hasEmail = provider.emailController.text.trim().isNotEmpty;
    final isEmailLocked = provider.isEmailLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Email",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (isVerified && !hasEmailChanged && hasEmail) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isEmailLocked) ...[
              SizedBox(width: 8.w),
              Icon(Icons.lock, color: Colors.grey, size: 16.sp),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isEmailLocked ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: hasEmailChanged && !isVerified && hasEmail
                ? Border.all(color: Colors.orange, width: 2.w)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: provider.emailController,
                  enabled: !isEmailLocked,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isEmailLocked
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: hasEmailChanged && !isVerified && hasEmail
                          ? Colors.orange
                          : ColorConstant.moyoOrange,
                      size: 24.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.red, width: 1.w),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.red, width: 2.w),
                    ),
                    filled: true,
                    fillColor: isEmailLocked
                        ? Colors.grey.shade100
                        : Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ),
              if (hasEmail &&
                  (hasEmailChanged || !isVerified) &&
                  !isEmailLocked)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ElevatedButton(
                    onPressed: provider.isEmailOtpLoading
                        ? null
                        : _handleVerifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isEmailOtpLoading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Verify',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (hasEmail && hasEmailChanged && !isEmailLocked) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isVerified
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isVerified
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Email verified successfully!'
                        : 'Email changed! Please verify your new email address before saving.',
                    style: TextStyle(
                      color: isVerified
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFieldWithVerify(EditProfileProvider provider) {
    final hasMobileChanged = provider.hasMobileChanged();
    final isVerified = provider.isMobileVerified;
    final hasMobile = provider.mobileController.text.trim().isNotEmpty;
    final isMobileLocked = provider.isMobileSet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Mobile Number",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (isVerified && !hasMobileChanged && hasMobile) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isMobileLocked) ...[
              SizedBox(width: 8.w),
              Icon(Icons.lock, color: Colors.grey, size: 16.sp),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isMobileLocked ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: hasMobileChanged && !isVerified && hasMobile
                ? Border.all(color: Colors.orange, width: 2.w)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: provider.mobileController,
                  enabled: !isMobileLocked,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isMobileLocked
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your mobile number",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: hasMobileChanged && !isVerified && hasMobile
                          ? Colors.orange
                          : ColorConstant.moyoOrange,
                      size: 24.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.red, width: 1.w),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.red, width: 2.w),
                    ),
                    filled: true,
                    fillColor: isMobileLocked
                        ? Colors.grey.shade100
                        : Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ),
              if (hasMobile &&
                  (hasMobileChanged || !isVerified) &&
                  !isMobileLocked)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ElevatedButton(
                    onPressed: provider.isMobileOtpLoading
                        ? null
                        : _handleVerifyMobile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.moyoOrange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isMobileOtpLoading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Verify',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (hasMobile && hasMobileChanged && !isMobileLocked) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isVerified
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isVerified
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Mobile verified successfully!'
                        : 'Mobile changed! Please verify your new mobile number before saving.',
                    style: TextStyle(
                      color: isVerified
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderSelector(EditProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGenderOption(provider, "Male", "male", Icons.male),
              ),
              Expanded(
                child: _buildGenderOption(
                  provider,
                  "Female",
                  "female",
                  Icons.female,
                ),
              ),
              Expanded(
                child: _buildGenderOption(
                  provider,
                  "Other",
                  "other",
                  Icons.transgender,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    EditProfileProvider provider,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = provider.selectedGender == value;
    return GestureDetector(
      onTap: () => provider.setGender(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.moyoOrange.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorConstant.moyoOrange
                  : Colors.grey.shade400,
              size: 28.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? ColorConstant.moyoOrange
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            style: TextStyle(
              fontSize: 16.sp,
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16.sp,
              ),
              prefixIcon: Icon(
                icon,
                color: ColorConstant.moyoOrange,
                size: 24.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.red, width: 1.w),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.red, width: 2.w),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
