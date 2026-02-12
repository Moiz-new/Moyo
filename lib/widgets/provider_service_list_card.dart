import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class ProviderServiceListCard extends StatefulWidget {
  final String? category;
  final String? subCategory;
  final String? date;
  final String? dp;
  final String? price;
  final String? duration;
  final String? priceBy;
  final int? providerCount;
  final String status;
  final DateTime? createdAt;
  final int timerDurationMinutes;
  final VoidCallback? onPress;
  final VoidCallback? onTimerComplete;

  const ProviderServiceListCard({
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
    this.createdAt,
    this.timerDurationMinutes = 60,
    this.onPress,
    this.onTimerComplete,
  });

  @override
  State<ProviderServiceListCard> createState() =>
      _ProviderServiceListCardState();
}

class _ProviderServiceListCardState extends State<ProviderServiceListCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Start timer immediately when card is added to the list
    if (widget.status.toLowerCase() == "open" && widget.createdAt != null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(ProviderServiceListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only restart timer if createdAt actually changed (new service)
    if (oldWidget.createdAt != widget.createdAt) {
      _timer?.cancel();
      if (widget.status.toLowerCase() == "open" && widget.createdAt != null) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    final elapsed = DateTime.now().difference(widget.createdAt!);
    final totalDuration = Duration(minutes: widget.timerDurationMinutes);
    _remainingTime = totalDuration - elapsed;

    if (_remainingTime.isNegative || _remainingTime.inSeconds <= 0) {
      // Timer already expired
      _remainingTime = Duration.zero;
      _progress = 0.0;
      // Immediately notify parent to remove this item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onTimerComplete != null && mounted) {
          widget.onTimerComplete!();
        }
      });
      return;
    }

    // Calculate initial progress
    _progress = _remainingTime.inSeconds / totalDuration.inSeconds;

    // Start countdown timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= Duration(seconds: 1);
          _progress = _remainingTime.inSeconds / totalDuration.inSeconds;
        } else {
          // Timer completed
          _timer?.cancel();
          _remainingTime = Duration.zero;
          _progress = 0.0;

          // Notify parent to remove this item from list
          if (widget.onTimerComplete != null) {
            widget.onTimerComplete!();
          }
        }
      });
    });

    debugPrint(
      '⏱️ Timer started for service: ${widget.category} - ${widget.subCategory}',
    );
    debugPrint('⏱️ Remaining time: ${_formatTime(_remainingTime)}');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool showTimer =
        widget.status.toLowerCase() == "open" && widget.createdAt != null;

    return InkWell(
      onTap: widget.onPress,
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
                        "${widget.category} > ${widget.subCategory}",
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
                      widget.date ?? "No date",
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
                            imageUrl: widget.dp!,
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
                                  "₹ ${widget.price ?? "No price"} /-",
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
                                "for ${widget.duration ?? "No Duration"}",
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
                                    widget.priceBy ?? "N/A",
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
                                    if (widget.status == "No status")
                                      Text(
                                        "${widget.providerCount ?? "No Count"}",
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
                                    if (widget.status == "No status")
                                      Icon(
                                        Icons.work_outline,
                                        color: ColorConstant.moyoOrange,
                                      ),
                                    currentStatusChip(context, widget.status),
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

              // Animated timer bar - shows remaining time
              if (showTimer)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      width: MediaQuery.of(context).size.width * _progress,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _progress > 0.3
                            ? ColorConstant.moyoGreen
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget currentStatusChip(BuildContext context, String status) {
    final statusLower = status.toLowerCase();

    switch (statusLower) {
      case 'open':
        return _buildStatusChip(
          context,
          text: "Open",
          backgroundColor: Color(0xFFE8F5E9),
          textColor: ColorConstant.moyoGreen,
        );

      case 'pending':
        return _buildStatusChip(
          context,
          text: "Pending",
          backgroundColor: Color(0xFFFFF3E0),
          textColor: Color(0xFFF57C00),
        );

      case 'assigned':
        return _buildStatusChip(
          context,
          text: "Assigned",
          backgroundColor: Color(0xFFDEEAFA),
          textColor: Color(0xFF1A4E88),
        );

      case 'started':
        return _buildStatusChip(
          context,
          text: "Started",
          backgroundColor: Color(0xFFE1F5FE),
          textColor: Color(0xFF0277BD),
        );

      case 'arrived':
        return _buildStatusChip(
          context,
          text: "Arrived",
          backgroundColor: Color(0xFFE8EAF6),
          textColor: Color(0xFF3F51B5),
        );

      case 'progress':
        return _buildStatusChip(
          context,
          text: "In Progress",
          backgroundColor: Color(0xFFFFF9C4),
          textColor: Color(0xFFF57F17),
        );

      case 'completed':
        return _buildStatusChip(
          context,
          text: "Completed",
          backgroundColor: Color(0xFFE6F7C0),
          textColor: ColorConstant.moyoGreen,
        );

      case 'cancelled':
        return _buildStatusChip(
          context,
          text: "Cancelled",
          backgroundColor: Color(0xFFFEE8E8),
          textColor: Color(0xFFDB4A4C),
        );

      case 'closed':
        return _buildStatusChip(
          context,
          text: "Closed",
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF616161),
        );

      default:
        return SizedBox(width: 0, height: 0);
    }
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.roboto(
          textStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          color: textColor,
        ),
      ),
    );
  }
}
