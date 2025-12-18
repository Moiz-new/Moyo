import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/ServiceProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_Pending_service.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_completed_service.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/user_ongoing_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/user_tab_bar.dart';

class UserService extends StatefulWidget {
  const UserService({super.key});

  @override
  State<UserService> createState() => _UserServiceState();
}

class _UserServiceState extends State<UserService>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Refresh data when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentTab();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures refresh when navigating back to this screen
    _refreshCurrentTab();
  }

  Future<void> _refreshCurrentTab() async {
    if (mounted) {
      final provider = context.read<ServiceProvider>();
      await provider.refreshServices();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserTabBar(controller: _tabController),
        Expanded(child: _tabBarView()),
      ],
    );
  }

  Widget _tabBarView() {
    return TabBarView(
      controller: _tabController,
      children: const [
        UserPendingService(),
        UserOngoingService(),
        UserCompletedService(),
      ],
    );
  }
}
