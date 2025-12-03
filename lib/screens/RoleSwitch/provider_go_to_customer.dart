import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colorConstant/color_constant.dart';
import '../../providers/user_navigation_provider.dart';
import '../commonOnboarding/splashScreen/splash_screen_provider.dart';

enum Mode { customer, provider }

class ProviderGoToCustomer extends StatefulWidget {
  const ProviderGoToCustomer({super.key});

  @override
  State<ProviderGoToCustomer> createState() => _ProviderGoToCustomerState();
}

class _ProviderGoToCustomerState extends State<ProviderGoToCustomer> {
  bool _isLoading = false;

  Future<void> _switchToCustomerMode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        _showErrorDialog('Authentication token not found. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update user role to customer
      await prefs.setString('user_role', 'customer');

      print('Switched to customer mode');
      print('Auth token exists: ${authToken.isNotEmpty}');
      print('User role updated to: customer');

      // Navigate to customer screen
      if (mounted) {
        Navigator.pushNamed(context, "/UserCustomBottomNav");
        context.read<UserNavigationProvider>().currentIndex = 0;
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final splashProvider = Provider.of<SplashProvider>(
        context,
        listen: false,
      );

      // Clear all session data
      await splashProvider.clearSession();

      print('User logged out successfully');

      // Navigate to login screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      _showErrorDialog('Logout failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleLogout(); // Perform logout
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            SvgPicture.asset('assets/icons/switch_role.svg'),
                            Text(
                              "Switch Role",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        // Logout Button
                        IconButton(
                          onPressed: _isLoading
                              ? null
                              : _showLogoutConfirmationDialog,
                          icon: Icon(
                            Icons.logout,
                            color: _isLoading ? Colors.grey : Colors.red,
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    _text1(context),
                    Column(
                      spacing: 40,
                      children: [
                        _customerProvider(context),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: 200,
                              child: _cancelSwitchButton(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _text1(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Text(
        "Would you like to switch to Customer mode?",
        textAlign: TextAlign.center,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF7A7A7A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _customerProvider(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: [
        Expanded(child: _switchModeContainer(context, Mode.customer, false)),
        Expanded(child: _switchModeContainer(context, Mode.provider, true)),
      ],
    );
  }

  Widget _switchModeContainer(BuildContext context, Enum mode, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive
            ? ColorConstant.moyoOrangeFade
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? ColorConstant.moyoOrange : const Color(0xFF7B7B7B),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 6,
        children: [
          isActive && mode == Mode.customer
              ? SvgPicture.asset("assets/icons/customer_mode_active.svg")
              : isActive && mode == Mode.provider
              ? SvgPicture.asset("assets/icons/provider_mode_active.svg")
              : isActive == false && mode == Mode.customer
              ? SvgPicture.asset("assets/icons/customer_mode_blur.svg")
              : SvgPicture.asset("assets/icons/provider_mode_blur.svg"),
          Text(
            mode == Mode.customer ? "Customer Mode" : "Provider Mode",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isActive
                  ? ColorConstant.moyoOrange
                  : const Color(0xFF7B7B7B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            mode == Mode.customer ? "Book services" : "Offer services",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive
                  ? ColorConstant.moyoOrange
                  : const Color(0xFF7B7B7B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelSwitchButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    "Cancel",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _isLoading
                          ? Colors.grey
                          : ColorConstant.moyoOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : ColorConstant.moyoOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _isLoading ? null : _switchToCustomerMode,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    "Switch",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
