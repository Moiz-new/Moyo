import 'package:flutter/material.dart';

import '../constants/colorConstant/color_constant.dart';

class UserTabBar extends StatelessWidget {
  final TabController? controller;

  const UserTabBar({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.bottomCenter,
      child: TabBar(
        controller: controller,
        indicatorColor: ColorConstant.moyoOrange,
        labelColor: ColorConstant.black,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
         /* Tab(
            icon: Text(
              "Pending",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(height: 1.11),
            ),
          ),*/
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
