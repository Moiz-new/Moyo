import 'package:first_flutter/screens/RoleSwitch/provider_go_to_customer.dart';
import 'package:first_flutter/widgets/user_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_navigation_provider.dart';
import 'navigation/provider_earning_screen_body.dart';
import 'navigation/provider_home_screen_body.dart';
import 'navigation/provider_service.dart';

class ProviderCustomBottomNav extends StatelessWidget {
  const ProviderCustomBottomNav({super.key});

  static const List<Widget> _pages = [
    ProviderHomeScreenBody(),
    ProviderService(),
    ProviderEarningScreenBody(),
    ProviderGoToCustomer(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppbar(
        dp: "https://picsum.photos/200/200",
        fullName: 'Friends',
        type:"provider"
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer<ProviderNavigationProvider>(
        builder: (context, ProviderNavigationProvider, child) {
          return _pages[ProviderNavigationProvider.currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: context.watch<ProviderNavigationProvider>().currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,

        selectedLabelStyle:
            // Theme.of(context).textTheme.labelMedium,
            TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
        unselectedLabelStyle: TextStyle(color: Colors.black87),
        unselectedItemColor: Colors.black87,
        onTap: (index) {
          // Provider.of<ProviderNavigationProvider>(
          //   context,
          //   listen: false,
          // ).setCurrentIndex(index);
          context.read<ProviderNavigationProvider>().setCurrentIndex(index);
        },
        showUnselectedLabels: true,
        items: [
          _buildNavItem(context, Icons.home, "Home", 0),
          _buildNavItem(context, Icons.calendar_today_outlined, "All Bids", 1),
          _buildNavItem(context, Icons.currency_rupee, "Earning", 2),
          _buildNavItem(context, Icons.work_outline, "Go to Customer", 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive =
        context.watch<ProviderNavigationProvider>().currentIndex == index;

    // print(
    //   "Current index is ${context.watch<ProviderNavigationProvider>().currentIndex}. and isActive = $isActive",
    // );
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.fromLTRB(6, 16, 6, 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Color(0xFFFEE4D3) : Colors.transparent,
          border: isActive ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Icon(icon, color: isActive ? Colors.orange : Colors.black87),
      ),
      label: label,
    );
  }
}
