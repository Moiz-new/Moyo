import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserServiceListCard extends StatelessWidget {
  final String? category;
  final String? subCategory;
  final String? date;
  final String? dp;
  final String? price;
  final String? duration;
  final String? priceBy;
  final int? providerCount;
  final String status;

  final VoidCallback? onPress;
  final VoidCallback? onInvoicePress;

  const UserServiceListCard({
    super.key,
    this.category,
    this.subCategory,
    this.date,
    this.dp,
    this.price,
    this.duration,
    this.priceBy,
    this.providerCount,
    this.status = "No status",
    this.onPress,
    this.onInvoicePress,
  });

  @override
  Widget build(BuildContext context) {
    print(priceBy);
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),

          child: Column(
            children: [
              Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "$category > $subCategory",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ),
                    Text(
                      date ?? "No date",
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: Colors.black.withAlpha(100)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      height: 58,
                      width: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: dp!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Image.asset(
                              'assets/images/moyo_image_placeholder.png',
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/moyo_image_placeholder.png',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "₹ ${priceBy ?? "No price"} /-",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                    color: Color(0xFF1D1B20),
                                  ),
                                ),
                              ),
                              Text(
                                "for ${duration ?? "No Duration"}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: GoogleFonts.roboto(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                    color: ColorConstant.moyoOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstant.moyoOrangeFade,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                  ),
                                  child: Text(
                                    category ?? "N/A",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: ColorConstant.moyoOrange,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                alignment: Alignment.center,
                                child: Row(
                                  spacing: 6,
                                  children: [
                                    if (status == "No status")
                                      Text(
                                        "${providerCount ?? "No Count"}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          color: ColorConstant.moyoOrange,
                                        ),
                                      ),
                                    if (status == "No status")
                                      Icon(
                                        Icons.work_outline,
                                        color: ColorConstant.moyoOrange,
                                      ),

                                    /// Status Chip
                                    currentStatusChip(context, status),

                                    /// Invoice Button (only visible when completed)
                                    if (status == 'completed')
                                      InkWell(
                                        onTap: onInvoicePress,
                                        child: Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: ColorConstant.moyoOrange,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),


                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget currentStatusChip(BuildContext context, String status) {
    switch (status) {
      case 'ongoing':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFDEEAFA),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            "Ongoing",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              color: Color(0xFF1A4E88),
            ),
          ),
        );
      case 'completed':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFE6F7C0),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            "Completed",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              color: ColorConstant.moyoGreen,
            ),
          ),
        );
      case 'cancelled':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFFEE8E8),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            "Cancelled",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              color: Color(0xFFDB4A4C),
            ),
          ),
        );
      case 'in_progress':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFFEE8E8),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            "In Progress",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              color: Color(0xFFDB4A4C),
            ),
          ),
        );

        case 'assigned':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFDEEAFA),
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            "Assigned",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              color: Color(0xFF1A4E88),
            ),
          ),
        );

      default:
        return SizedBox(width: 0, height: 0);
    }
  }
}