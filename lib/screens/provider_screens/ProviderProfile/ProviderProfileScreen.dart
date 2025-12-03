
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/button_large.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/personal_info_card.dart';
import 'ProviderProfileProvider.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = context.read<ProviderProfileProvider>();
    await provider.loadProviderProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: "Provider Profile"),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer<ProviderProfileProvider>(
        builder: (context, profileProvider, child) {
          // Show loading indicator
          if (profileProvider.isLoading && !profileProvider.hasProfile) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorConstant.moyoOrange,
              ),
            );
          }

          // Show error message
          if (profileProvider.errorMessage != null && !profileProvider.hasProfile) {
            return _buildErrorWidget(context, profileProvider);
          }

          // Show profile data
          return RefreshIndicator(
            onRefresh: () => profileProvider.refreshProfile(),
            color: ColorConstant.moyoOrange,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 30,
                  children: [
                    _profilePic(context, profileProvider.profileImage),
                    _personalInformation(context, profileProvider),
                    _professionalInformation(context, profileProvider),
                    _accountStatus(context, profileProvider),
                    ButtonLarge(
                      isIcon: false,
                      label: "Edit Profile",
                      backgroundColor: ColorConstant.moyoOrange,
                      labelColor: Colors.white,
                      onTap: () async {
                        final result = await Navigator.pushNamed(context, '/editProviderProfile');
                        if (result == true) {
                          profileProvider.refreshProfile();
                        }
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, ProviderProfileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.loadProviderProfile();
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePic(BuildContext context, String? imageUrl) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: ColorConstant.moyoOrange.withOpacity(0.3),
          width: 2,
        ),
      ),
      height: 155,
      width: 155,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl,
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
            )
          else
            Image.asset(
              'assets/images/moyo_image_placeholder.png',
              fit: BoxFit.cover,
            ),
        ],
      ),
    );
  }

  Widget _personalInformation(
      BuildContext context, ProviderProfileProvider profileProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Personal Information",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        PersonalInfoCard(
          isLabel: true,
          label: "Full Name",
          title: profileProvider.fullName,
          iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
        ),
        if (profileProvider.providerProfile?.email != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Email",
            title: profileProvider.email,
            iconPath: 'assets/icons/moyo_icon_info_card_email.svg',
          ),
        PersonalInfoCard(
          isLabel: true,
          label: "Phone Number",
          title: profileProvider.mobile,
          iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
        ),
        if (profileProvider.providerProfile?.age != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Age",
            title: profileProvider.providerProfile!.age.toString(),
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        if (profileProvider.providerProfile?.gender != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Gender",
            title: profileProvider.providerProfile!.gender!,
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        if (profileProvider.providerProfile?.adharNo != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Aadhaar Number",
            title: profileProvider.providerProfile!.adharNo!,
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
      ],
    );
  }

  Widget _professionalInformation(
      BuildContext context, ProviderProfileProvider profileProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Professional Information",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (profileProvider.providerProfile?.service != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Service",
            title: profileProvider.service,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.providerProfile?.experience != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Experience",
            title: profileProvider.experience,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.providerProfile?.education != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Education",
            title: profileProvider.education,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.providerProfile?.keySkills != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Key Skills",
            title: profileProvider.keySkills,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.providerProfile?.licenseCertified != null)
          PersonalInfoCard(
            isLabel: true,
            label: "License/Certification",
            title: profileProvider.providerProfile!.licenseCertified!,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.providerProfile?.latitude != null &&
            profileProvider.providerProfile?.longitude != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Location",
            title: '${profileProvider.providerProfile!.latitude}, ${profileProvider.providerProfile!.longitude}',
            iconPath: 'assets/icons/moyo_icon_info_card_address.svg',
          ),
      ],
    );
  }

  Widget _accountStatus(
      BuildContext context, ProviderProfileProvider profileProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Account Status",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _buildStatusCard(
          context,
          "Registration Status",
          profileProvider.isRegistered ? "Registered" : "Not Registered",
          profileProvider.isRegistered,
        ),
        _buildStatusCard(
          context,
          "Active Status",
          profileProvider.isActive ? "Active" : "Inactive",
          profileProvider.isActive,
        ),
        if (profileProvider.providerProfile?.providerCreatedAt != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Provider Since",
            title: _formatDate(profileProvider.providerProfile!.providerCreatedAt),
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        PersonalInfoCard(
          isLabel: true,
          label: "Provider ID",
          title: profileProvider.providerProfile!.id.toString(),
          iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String label, String value, bool isPositive) {
    return Container(
      padding: EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}