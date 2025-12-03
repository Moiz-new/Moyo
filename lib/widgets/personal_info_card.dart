import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalInfoCard extends StatelessWidget {
  final String iconPath;
  final String? label;
  final String? title;
  final bool isLabel;
  final VoidCallback? onPress;
  final bool showArrow; // <-- NEW

  const PersonalInfoCard({
    super.key,
    this.iconPath = "assets/icons/moyo_address_card_home_icon.svg",
    this.label,
    this.title,
    this.isLabel = true,
    this.onPress,
    this.showArrow = false, // <-- default false (original behavior)
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            SvgPicture.asset(iconPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (isLabel) _label(context, label),
                  _title(context, title),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String? label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Text(
        label ?? "No label",
        textAlign: TextAlign.start,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF7A7A7A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String? title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Text(
        title ?? "No title",
        textAlign: TextAlign.start,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF000000),
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
