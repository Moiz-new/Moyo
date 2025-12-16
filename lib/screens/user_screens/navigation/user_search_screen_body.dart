import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/colorConstant/color_constant.dart';
import '../../../widgets/UpdateProfileDialog.dart';
import '../../../widgets/user_expansion_tile_list_card.dart';
import '../User Instant Service/user_instant_service_screen.dart';
import 'UserSearchProvider.dart';

class UserSearchScreenBody extends StatefulWidget {
  const UserSearchScreenBody({super.key});

  @override
  State<UserSearchScreenBody> createState() => _UserSearchScreenBodyState();
}

class _UserSearchScreenBodyState extends State<UserSearchScreenBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSearchProvider(),
      child: Consumer<UserSearchProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSearchField(context, provider),
                  Flexible(child: _buildResultsSection(context, provider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, UserSearchProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        provider.searchUsers(value);
      },
      style:
          Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w400,
          ) ??
          const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEEEEEE),
        alignLabelWithHint: true,
        hintText: 'Search for services..',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: provider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              )
            : _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstant.moyoOrange.withAlpha(0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstant.moyoOrange),
        ),
      ),
      maxLines: 1,
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    UserSearchProvider provider,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return _notAvailable(context, provider.error);
    }

    if (!provider.hasResults && provider.searchKeyword.isEmpty) {
      return _searchForServices(context);
    }

    if (!provider.hasResults) {
      return _notAvailable(context, 'No services found');
    }

    return _userSearchResults(context, provider);
  }

  Widget _searchForServices(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/moyo_big_search.svg',
            color: Colors.grey[400],
          ),
          Text(
            'Search for services',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a valid field to find your required service',
            maxLines: 2,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                ) ??
                const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _notAvailable(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/not_available_big_icon.svg'),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            maxLines: 2,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF686868),
                  fontWeight: FontWeight.w400,
                ) ??
                const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _userSearchResults(BuildContext context, UserSearchProvider provider) {
    return Expanded(
      child: ListView.builder(
        itemCount: provider.users.length,
        itemBuilder: (context, index) {
          final user = provider.users[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            child: UserExpansionTileListCard(
              dp: user.icon.isNotEmpty
                  ? user.icon
                  : 'https://picsum.photos/200/200',
              title: user.name.isNotEmpty ? user.name : 'Unknown Service',
              subtitle: 'in ${user.name.isNotEmpty ? user.name : 'Service'}',
              onServiceTypeSelected: (serviceType) =>
                  _handleServiceTypeSelection(context, user, serviceType),
            ),
          );
        },
      ),
    );
  }

  void _handleServiceTypeSelection(
    BuildContext context,
    UserSearchData subcategory,
    String serviceType,
  ) async {
    print(subcategory.id);
    print(subcategory.categoryId);
    final prefs = await SharedPreferences.getInstance();
    final isEmailVerified = prefs.getBool('is_email_verified') ?? false;
    final userMobile = prefs.getString('user_mobile') ?? '';

    // ADD THIS CHECK:
    if (!isEmailVerified || userMobile.isEmpty) {
      // Email not verified OR mobile not provided, show dialog first
      print(
        'Email not verified or mobile missing, showing update profile dialog',
      );

      await UpdateProfileDialog.show(context);

      // After dialog closes, check again if both are now verified
      final updatedPrefs = await SharedPreferences.getInstance();
      final updatedEmailVerified =
          updatedPrefs.getBool('is_email_verified') ?? false;
      final updatedMobile = updatedPrefs.getString('user_mobile') ?? '';

      if (!updatedEmailVerified || updatedMobile.isEmpty) {
        // Still not complete, don't proceed
        print('Profile still incomplete after dialog');
        return;
      }
      // Both verified, continue to service screen below
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInstantServiceScreen(
          categoryId: subcategory.id,
          categoryName: subcategory.name,
          serviceType: serviceType,
        ),
      ),
    );
  }
}
