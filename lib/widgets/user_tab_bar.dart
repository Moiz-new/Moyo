import 'package:flutter/material.dart';

import '../constants/colorConstant/color_constant.dart';

class UserTabBar extends StatelessWidget {
  const UserTabBar({super.key});

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
              "Pending",
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
              "Ongoing",
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
              'Completed',
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
