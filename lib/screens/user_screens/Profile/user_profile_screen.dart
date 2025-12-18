// screens/user_profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/screens/user_screens/Address/AddAddressScreen.dart';
import 'package:first_flutter/screens/user_screens/Address/MyAddressesScreen.dart';
import 'package:first_flutter/widgets/button_large.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/personal_info_card.dart';
import 'FAQScreen.dart';
import 'UserProfileProvider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = context.read<UserProfileProvider>();
    await provider.loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: "Profile"),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer<UserProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && !profileProvider.hasProfile) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
            );
          }

          if (profileProvider.errorMessage != null &&
              !profileProvider.hasProfile) {
            return _buildErrorWidget(context, profileProvider);
          }

          return RefreshIndicator(
            onRefresh: () => profileProvider.refreshProfile(),
            color: ColorConstant.moyoOrange,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 30,
                  children: [
                    _profilePic(context, profileProvider.profileImage),
                    _personalInformation(context, profileProvider),
                    _accountInformation(context, profileProvider),
                    _accountStatus(context, profileProvider),
                    // Show provider section only if provider data exists
                    if (profileProvider.userProfile?.hasProviderData ?? false)
                      _providerInformation(context, profileProvider),
                    ButtonLarge(
                      isIcon: false,
                      label: "Edit Profile",
                      backgroundColor: ColorConstant.moyoOrange,
                      labelColor: Colors.white,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/editProfile',
                        );
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

  Widget _buildErrorWidget(BuildContext context, UserProfileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.loadUserProfile();
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


  String capitalizeName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _personalInformation(
    BuildContext context,
    UserProfileProvider profileProvider,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Personal Information",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        PersonalInfoCard(
          isLabel: true,
          label: "Full Name",
          title: capitalizeName(profileProvider.fullName),
          iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
        ),
        if (profileProvider.userProfile?.username != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Username",
            title: profileProvider.userProfile!.username!,
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
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
        if (profileProvider.userProfile?.age != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Age",
            title: profileProvider.userProfile!.age.toString(),
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        if (profileProvider.userProfile?.gender != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Gender",
            title: profileProvider.userProfile!.gender!,
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        PersonalInfoCard(
          isLabel: false,
          label: "Address",
          title: 'Address Book',
          iconPath: 'assets/icons/moyo_icon_info_card_address.svg',
          showArrow: true,
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyAddressesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _accountInformation(
    BuildContext context,
    UserProfileProvider profileProvider,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Account Information",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (profileProvider.referralCode.isNotEmpty)
          PersonalInfoCard(
            isLabel: true,
            label: "Referral Code",
            title: profileProvider.referralCode,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (profileProvider.userProfile?.referredBy != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Referred By",
            title: profileProvider.userProfile!.referredBy!,
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
      ],
    );
  }

  Widget _accountStatus(
    BuildContext context,
    UserProfileProvider profileProvider,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Account Status",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
          "Email Verification",
          profileProvider.userProfile?.emailVerified ?? false
              ? "Verified"
              : "Not Verified",
          profileProvider.userProfile?.emailVerified ?? false,
        ),
        _buildStatusCard(
          context,
          "Provider Account",
          profileProvider.userProfile?.isProvider ?? false ? "Yes" : "No",
          profileProvider.userProfile?.isProvider ?? false,
        ),
        if (profileProvider.userProfile?.isBlocked ?? false)
          _buildStatusCard(context, "Account Status", "Blocked", false),
        if (profileProvider.userProfile?.createdAt != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Member Since",
            title: _formatDate(profileProvider.userProfile!.createdAt),
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
      ],
    );
  }

  String maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.isEmpty) return '';
    final clean = aadhaar.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final visible = clean.substring(clean.length - 4);
    final masked = '*' * (clean.length - 4);
    return masked + visible;
  }

  String maskPan(String? pan) {
    if (pan == null || pan.isEmpty) return '';
    final clean = pan.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final visible = clean.substring(clean.length - 4);
    final masked = '*' * (clean.length - 4);
    return masked + visible;
  }

  // New section for provider information
  Widget _providerInformation(
    BuildContext context,
    UserProfileProvider profileProvider,
  ) {
    final provider = profileProvider.userProfile?.provider;

    if (provider == null) return SizedBox.shrink();

    print(provider.isActive);
    print(provider.isRegistered);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Provider Information",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _buildStatusCard(
          context,
          "Provider Status",
          provider.isActive ? "Active" : "Inactive",
          provider.isActive,
        ),
        _buildStatusCard(
          context,
          "Provider Registration",
          provider.isRegistered ? "Registered" : "Not Registered",
          provider.isRegistered,
        ),
        PersonalInfoCard(
          isLabel: true,
          label: "Work Radius",
          title: "${provider.workRadius} km",
          iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
        ),
        if (provider.education != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Education",
            title: provider.education!,
            iconPath: 'assets/icons/moyo_icon_info_card_full_name.svg',
          ),
        if (provider.adharNo != null)
          PersonalInfoCard(
            isLabel: true,
            label: "Aadhaar Number",
            title: maskAadhaar(provider.adharNo),
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (provider.panNo != null)
          PersonalInfoCard(
            isLabel: true,
            label: "PAN Number",
            title: maskPan(provider.panNo),
            iconPath: 'assets/icons/moyo_icon_info_card_phone.svg',
          ),
        if (provider.isBlocked)
          _buildStatusCard(context, "Provider Status", "Blocked", false),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String label,
    String value,
    bool isPositive,
  ) {
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
                color: isPositive
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
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
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
