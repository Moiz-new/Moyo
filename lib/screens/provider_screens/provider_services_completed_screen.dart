import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/provider_only_title_appbar.dart';
import 'package:flutter/material.dart';

import '../../widgets/user_service_details.dart';

class ProviderServicesCompletedScreen extends StatelessWidget {
  const ProviderServicesCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.scaffoldGray,
      appBar: ProviderOnlyTitleAppbar(title: "Services Completed"),
      body: ListView(
        children: [
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
          UserServiceDetails(
            category: "Home",
            subCategory: "Cleaning",
            date: "Dec 07, 2025",
            pin: "2156",
            providerPhone: "8890879707",
            dp: "https://picsum.photos/200/200",
            name: "Aarif Husain",
            rating: "4.5",
            // status: "pending",
            // status: "ongoing",
            // status: "confirmed",
            status: "completed",
            // status: "cancelled",
            durationType: "Hourly",
            duration: "4 hours",
            price: "450",
            address:
                "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
            particular: ["Cooking", "Dessert", "5 Days", "4 People"],
            description:
                "This is the service description can write here which will be five line long",
          ),
        ],
      ),
    );
  }
}
