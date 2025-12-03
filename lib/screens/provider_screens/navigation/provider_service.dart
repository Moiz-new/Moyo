import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_bid_service.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_confirmed_service.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_re_bid_service.dart';
import 'package:flutter/material.dart';

import '../../../widgets/provider_tab_bar.dart';

class ProviderService extends StatelessWidget {
  const ProviderService({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          ProviderTabBar(),
          Expanded(child: tabBarView(context)),
        ],
      ),
    );
  }

  Widget tabBarView(BuildContext context) {
    return TabBarView(
      children: [
        ProviderBidService(),
        ProviderReBidService(),
        ProviderConfirmedService(),
      ],
    );
  }
}
