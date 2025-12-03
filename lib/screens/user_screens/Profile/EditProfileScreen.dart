
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/button_large.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'EditProfileProvider.dart';
import 'UserProfileProvider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
    });
  }

  void _initializeProfile() {
    final userProvider = context.read<UserProfileProvider>();
    final editProvider = context.read<EditProfileProvider>();

    if (userProvider.hasProfile) {
      editProvider.initializeProfile(
        firstname: userProvider.userProfile?.firstname ?? '',
        lastname: userProvider.userProfile?.lastname ?? '',
        email: userProvider.email,
        username: userProvider.userProfile?.username,
        age: userProvider.userProfile?.age,
        gender: userProvider.userProfile?.gender,
        imageUrl: userProvider.profileImage,
      );
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: ColorConstant.moyoOrange),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                context.read<EditProfileProvider>().pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: ColorConstant.moyoOrange),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                context.read<EditProfileProvider>().pickImageFromCamera();
              },
            ),
            if (context.read<EditProfileProvider>().selectedImage != null ||
                context.read<EditProfileProvider>().currentImageUrl != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<EditProfileProvider>().removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final editProvider = context.read<EditProfileProvider>();
    final success = await editProvider.updateProfile();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.successMessage ?? 'Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: "Edit Profile"),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer<EditProfileProvider>(
        builder: (context, editProvider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    _buildProfileImage(editProvider),
                    SizedBox(height: 30),
                    _buildForm(editProvider),
                    SizedBox(height: 30),
                    ButtonLarge(
                      isIcon: false,
                      label: "Save Changes",
                      backgroundColor: ColorConstant.moyoOrange,
                      labelColor: Colors.white,
                      onTap: editProvider.isLoading ? null : _handleSave,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              if (editProvider.isLoading)
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
            height: 155,
            width: 155,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: ColorConstant.moyoOrange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _buildImageContent(provider),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(EditProfileProvider provider) {
    if (provider.selectedImage != null) {
      return Image.file(
        provider.selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (provider.currentImageUrl != null && provider.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: provider.currentImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: ColorConstant.moyoOrange,
            strokeWidth: 2,
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
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: provider.lastnameController,
          label: "Last Name",
          icon: Icons.person_outline,
          hint: "Enter your last name",
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: provider.usernameController,
          label: "Username",
          icon: Icons.alternate_email,
          hint: "Enter your username",
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: provider.emailController,
          label: "Email",
          icon: Icons.email_outlined,
          hint: "Enter your email",
          enabled: false, // Email cannot be changed
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: provider.ageController,
          label: "Age",
          icon: Icons.cake_outlined,
          hint: "Enter your age",
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        _buildGenderSelector(provider),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: ColorConstant.moyoOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  provider,
                  "Male",
                  "male",
                  Icons.male,
                ),
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
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstant.moyoOrange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? ColorConstant.moyoOrange : Colors.grey.shade400,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? ColorConstant.moyoOrange : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}