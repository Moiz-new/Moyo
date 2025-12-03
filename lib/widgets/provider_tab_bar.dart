import 'package:flutter/material.dart';

import '../constants/colorConstant/color_constant.dart';

class ProviderTabBar extends StatelessWidget {
  const ProviderTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.bottomCenter,
      child: TabBar(
        indicatorColor: ColorConstant.moyoOrange,
        labelColor: ColorConstant.black,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            icon: Text(
              "Bid",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(height: 1.11),
            ),
          ),
          Tab(
            icon: Text(
              "Re Bid",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(height: 1.11),
            ),
          ),
          Tab(
            icon: Text(
              'Confirmed',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(height: 1.11),
            ),
          ),
        ],
      ),
    );
  }
}
