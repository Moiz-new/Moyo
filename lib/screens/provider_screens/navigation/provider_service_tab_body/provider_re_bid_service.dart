import 'package:flutter/material.dart';

import '../../../../widgets/provider_service_list_card.dart';

class ProviderReBidService extends StatelessWidget {
  const ProviderReBidService({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ProviderServiceListCard(
          category: "Home",
          subCategory: "Cleaning",
          date: "Dec 07, 2025",
          dp: "https://picsum.photos/200/200",
          price: "250",
          duration: "4 hours",
          priceBy: "Hourly",
          providerCount: 7,
          status: "accepted",
          // status: "Time out",
          // status: "Bided",
          // status: "Completed",
          // status: "Cancelled",
          onPress: () {
            Navigator.pushNamed(context, "/provider_bid_details");
          },
        ),
      ],
    );
  }
}
