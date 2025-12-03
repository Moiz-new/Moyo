import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colorConstant/color_constant.dart';

class ProviderJobOfferingCard extends StatefulWidget {
  final bool verified;
  final String subCat;
  final String? serviceName;
  final String? experience;
  final String? status;
  final bool isChecked;
  final Function(bool)? onToggle;

  const ProviderJobOfferingCard({
    super.key,
    this.verified = false,
    required this.subCat,
    this.serviceName,
    this.experience,
    this.status,
    this.isChecked = false,
    this.onToggle,
  });

  @override
  State<ProviderJobOfferingCard> createState() => _ProviderJobOfferingCardState();
}

class _ProviderJobOfferingCardState extends State<ProviderJobOfferingCard> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.isChecked;
  }

  @override
  void didUpdateWidget(ProviderJobOfferingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      _isActive = widget.isChecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorConstant.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subCat,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.roboto(
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColorConstant.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.serviceName != null) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.serviceName!,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                  if (widget.experience != null) ...[
                    SizedBox(height: 2),
                    Text(
                      '${widget.experience} years experience',
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _currentStatusChip(context, widget.verified),
                SizedBox(width: 10),
                Switch.adaptive(
                  thumbColor: WidgetStateProperty.all(ColorConstant.white),
                  activeTrackColor: ColorConstant.moyoGreen,
                  inactiveTrackColor: ColorConstant.scaffoldGray,
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.white.withOpacity(0),
                  ),
                  value: _isActive,
                  onChanged: widget.verified ? (value) {
                    setState(() {
                      _isActive = value;
                    });
                    if (widget.onToggle != null) {
                      widget.onToggle!(value);
                    }
                  } : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentStatusChip(BuildContext context, bool verified) {
    // Handle different status values from API
    final status = widget.status?.toLowerCase() ?? (verified ? 'approved' : 'pending');

    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case 'approved':
        backgroundColor = Color(0xFFE6F7C0);
        textColor = ColorConstant.moyoGreen;
        statusText = 'Verified';
        break;
      case 'pending':
        backgroundColor = Color(0xFFFFF4E6);
        textColor = Color(0xFFFF9800);
        statusText = 'Pending';
        break;
      case 'rejected':
        backgroundColor = Color(0xFFFEE8E8);
        textColor = Color(0xFFDB4A4C);
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Color(0xFFFEE8E8);
        textColor = Color(0xFFDB4A4C);
        statusText = 'Not Verified';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Text(
        statusText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          color: textColor,
        ),
      ),
    );
  }
}