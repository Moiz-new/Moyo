import 'package:first_flutter/screens/user_screens/navigation/user_go_to_provider.dart';
import 'package:first_flutter/widgets/user_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_navigation_provider.dart';
import 'Home/user_home_screen_body.dart';
import 'navigation/user_search_screen_body.dart';
import 'navigation/user_service.dart';

class UserCustomBottomNav extends StatelessWidget {
  const UserCustomBottomNav({super.key});

  static const List<Widget> _pages = [
    UserHomeScreenBody(),
    UserSearchScreenBody(),
    UserService(),
    UserGoToProvider(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppbar(
        dp: "https://picsum.photos/200/200",
        fullName: 'Friends',
        type: 'user',
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer<UserNavigationProvider>(
        builder: (context, userNavigationProvider, child) {
          return _pages[userNavigationProvider.currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: context.watch<UserNavigationProvider>().currentIndex,
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
          // Provider.of<UserNavigationProvider>(
          //   context,
          //   listen: false,
          // ).setCurrentIndex(index);
          context.read<UserNavigationProvider>().setCurrentIndex(index);
        },
        showUnselectedLabels: true,
        items: [
          _buildNavItem(context, Icons.home, "Home", 0),
          _buildNavItem(context, Icons.search, "Search", 1),
          _buildNavItem(context, Icons.calendar_today_outlined, "Services", 2),
          _buildNavItem(context, Icons.person_outline, "Go to Provider", 3),
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
        context.watch<UserNavigationProvider>().currentIndex == index;

    // print(
    //   "Current index is ${context.watch<UserNavigationProvider>().currentIndex}. and isActive = $isActive",
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
