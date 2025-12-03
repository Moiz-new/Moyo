import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/colorConstant/color_constant.dart';
import '../../../widgets/user_expansion_tile_list_card.dart';

class UserSearchScreenBody extends StatelessWidget {
  const UserSearchScreenBody({super.key});

  final bool isResult = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSearchField(context),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isResult) _searchForServices(context),
                  if (!isResult) _notAvailable(context),
                  if (isResult) _subCategory(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 18,
        color: Color(0xFF000000),
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFEEEEEE),
        alignLabelWithHint: true,

        hint: Text(
          'Search for services..',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 18,
            color: Color(0xFF686868),
            fontWeight: FontWeight.w400,
          ),
        ),
        // hintText: 'Search for services..',
        prefixIcon: Icon(Icons.search),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstant.moyoOrange.withAlpha(0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstant.moyoOrange),
        ),
      ),
      maxLines: 1,
    );
  }

  Widget _searchForServices(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        mainAxisSize: MainAxisSize.max,
        children: [
          SvgPicture.asset('assets/icons/moyo_big_search.svg'),
          Text(
            'Search for services',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Color(0xFF000000),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Enter a valid field to find your required service',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 16,
              color: Color(0xFF686868),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notAvailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        mainAxisSize: MainAxisSize.max,
        children: [
          SvgPicture.asset('assets/icons/not_available_big_icon.svg'),

          Text(
            'Unfortunately, we are not able to fetch you any service providers at the moment',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 16,
              color: Color(0xFF686868),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subCategory(BuildContext context) {
    final services = [
      {
        'title': 'Chef',
        'subtitle': 'in Chef',
        'dp': 'https://picsum.photos/200/200',
      },
      {
        'title': 'Cook',
        'subtitle': 'in Cook',
        'dp': 'https://picsum.photos/200/200',
      },
      {
        'title': 'Chauffeur',
        'subtitle': 'in Chauffeur',
        'dp': 'https://picsum.photos/200/200',
      },
      {
        'title': 'Commercial Vehicle Driver',
        'subtitle': 'in Commercial Vehicle Driver',
        'dp': 'https://picsum.photos/200/200',
      },
      {
        'title': 'Class 11-12 Tutor',
        'subtitle': 'in Class 11-12 Tutor',
        'dp': 'https://picsum.photos/200/200',
      },
    ];
    return Expanded(
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            child: UserExpansionTileListCard(
              dp: service['dp'] ?? 'https://picsum.photos/200/200',
              title: service['title'] as String,
              subtitle: service['subtitle'] as String,
            ),
          );
        },
      ),
    );
  }
}
