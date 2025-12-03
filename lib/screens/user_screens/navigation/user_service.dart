import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_Pending_service.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_completed_service.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_ongoing_service.dart';
import 'package:flutter/material.dart';

import '../../../widgets/user_tab_bar.dart';

class UserService extends StatelessWidget {
  const UserService({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          UserTabBar(),
          Expanded(child: tabBarView(context)),
        ],
      ),
    );
  }

  Widget tabBarView(BuildContext context) {
    return TabBarView(
      children: [
        UserPendingService(),
        UserOngoingService(),
        UserCompletedService(),
      ],
    );
  }
}
