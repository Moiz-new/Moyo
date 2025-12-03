import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProviderOnlyTitleAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const ProviderOnlyTitleAppbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.white,
      backgroundColor: ColorConstant.moyoOrange,
      title: Text(
        title,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: ColorConstant.white,
          ),
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: true,
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
