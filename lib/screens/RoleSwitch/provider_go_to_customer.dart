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
                  children: [
                    // ✅ FIXED: Removed invalid 'spacing'
                    // ✅ FIXED: Centered title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ✅ Changed from spaceBetween
                      children: [
                        // ✅ Removed invalid 'spacing'
                        SvgPicture.asset('assets/icons/switch_role.svg'),
                        const SizedBox(width: 10), // ✅ Proper spacing
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
                    const SizedBox(height: 16), // ✅ Proper vertical spacing
                    _text1(context),
                    const SizedBox(height: 40), // ✅ Proper vertical spacing
                    _customerProvider(context),
                    const SizedBox(height: 20), // ✅ Proper vertical spacing
                    // ✅ FIXED: Centered Switch button
                    _switchButton(context), // New centered button method
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

  // ✅ NEW: Properly centered Switch button
  Widget _switchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey : ColorConstant.moyoOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _switchToCustomerMode,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                "Switch",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Remove invalid spacing from customerProvider
  Widget _customerProvider(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ Removed invalid 'spacing'
        Expanded(child: _switchModeContainer(context, Mode.customer, false)),
        const SizedBox(width: 16), // ✅ Proper spacing
        Expanded(child: _switchModeContainer(context, Mode.provider, true)),
      ],
    );
  }

  // ✅ FIXED: Remove invalid spacing from switchModeContainer
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
        children: [
          // ✅ Removed invalid 'spacing'
          isActive && mode == Mode.customer
              ? SvgPicture.asset("assets/icons/customer_mode_active.svg")
              : isActive && mode == Mode.provider
              ? SvgPicture.asset("assets/icons/provider_mode_active.svg")
              : isActive == false && mode == Mode.customer
              ? SvgPicture.asset("assets/icons/customer_mode_blur.svg")
              : SvgPicture.asset("assets/icons/provider_mode_blur.svg"),
          const SizedBox(height: 6), // ✅ Proper spacing
          Text(
            mode == Mode.customer ? "Customer Mode" : "Provider Mode",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isActive
                  ? ColorConstant.moyoOrange
                  : const Color(0xFF7B7B7B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // ✅ Proper spacing
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
}
