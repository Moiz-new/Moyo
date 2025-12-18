import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'ServiceTimerProvider.dart';

class ServiceTimerScreen extends StatelessWidget {
  final String serviceId;
  final String authToken;
  final int durationValue;
  final String durationUnit;
  final String? categoryName;
  final String? subCategoryName;

  const ServiceTimerScreen({
    super.key,
    required this.serviceId,
    required this.authToken,
    required this.durationValue,
    required this.durationUnit,
    this.categoryName,
    this.subCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ServiceTimerProvider(serviceId: serviceId, authToken: authToken),
      child: ServiceTimerScreenContent(
        categoryName: categoryName ?? 'Service',
        subCategoryName: subCategoryName ?? 'Category',
      ),
    );
  }
}

class ServiceTimerScreenContent extends StatelessWidget {
  final String categoryName;
  final String subCategoryName;

  const ServiceTimerScreenContent({
    super.key,
    required this.categoryName,
    required this.subCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF9800),
      body: Consumer<ServiceTimerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.white),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading service',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Top section with service provider image
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Background image with overlay
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: const NetworkImage(
                            'https://picsum.photos/400/300',
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 20.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 100.w,
                          height: 100.h,
                          child: Image.asset("assets/icons/app_icon.png"),
                        ),
                      ),
                    ),

                    // Service category
                    Positioned(
                      bottom: 20.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),
                            Text(
                              subCategoryName,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section with timer and controls
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 80.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        // Service category text
                        Text(
                          '$categoryName > $subCategoryName',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        Divider(thickness: 1, color: Colors.grey.shade300),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timer Clock
                            Expanded(
                              flex: 5,
                              child: CustomPaint(
                                size: Size(180.w, 180.w),
                                painter: TimerClockPainter(
                                  elapsedSeconds: provider.elapsedSeconds,
                                  allocatedSeconds: provider.allocatedSeconds,
                                  color: provider.getTimerColor(),
                                  isExtraTime: provider.isExtraTime,
                                ),
                                child: Container(
                                  width: 180.w,
                                  height: 180.w,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),

                            SizedBox(width: 14.w),

                            // Time info section
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20.h),

                                  // Elapsed/Extra Time Display
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: provider.isExtraTime
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      border: Border.all(
                                        color: provider.isExtraTime
                                            ? Colors.red
                                            : const Color(0xFF4CAF50),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          provider.isExtraTime
                                              ? 'Extra Time'
                                              : 'Elapsed Time',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: provider.isExtraTime
                                                ? Colors.red
                                                : const Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          provider.formatTime(
                                            provider.isExtraTime
                                                ? provider.getExtraTimeSeconds()
                                                : provider.elapsedSeconds,
                                          ),
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: provider.isExtraTime
                                                ? Colors.red
                                                : const Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 10.h),

                                  // Remaining Time Display
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF9800,
                                      ).withOpacity(0.1),
                                      border: Border.all(
                                        color: const Color(0xFFFF9800),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Remaining Time',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: const Color(0xFFFF9800),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          provider.isExtraTime
                                              ? '00:00:00'
                                              : provider.formatTime(
                                                  provider.remainingSeconds,
                                                ),
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: const Color(0xFFFF9800),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 15.w),
                            _buildActionButton(context, 'Cancellation', () {
                              // Handle cancellation
                            }),
                            SizedBox(width: 5.w),
                            _buildActionButton(context, 'SOS', () {
                              // Handle SOS
                              // Navigator.push(context, ...);
                            }),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Timer Clock (same as before)
class TimerClockPainter extends CustomPainter {
  final int elapsedSeconds;
  final int allocatedSeconds;
  final Color color;
  final bool isExtraTime;

  TimerClockPainter({
    required this.elapsedSeconds,
    required this.allocatedSeconds,
    required this.color,
    required this.isExtraTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final progressSeconds = isExtraTime ? allocatedSeconds : elapsedSeconds;
    final totalForProgress = isExtraTime ? allocatedSeconds : allocatedSeconds;
    final progressPercentage = progressSeconds / totalForProgress;
    final progressAngle = progressPercentage * 2 * pi;

    // Draw clock face background
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF3E0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress
    if (!isExtraTime && elapsedSeconds > 0) {
      final greenPaint = Paint()
        ..color = const Color(0xFF8BC34A)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progressAngle,
        false,
      );
      path.lineTo(center.dx, center.dy);
      path.close();

      canvas.drawPath(path, greenPaint);
    }

    if (isExtraTime) {
      final redBgPaint = Paint()
        ..color = const Color(0xFFFFF3E0)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, redBgPaint);

      final extraSeconds = elapsedSeconds - allocatedSeconds;
      final extraPercentage =
          (extraSeconds % allocatedSeconds) / allocatedSeconds;
      final extraAngle = extraPercentage * 2 * pi;

      if (extraSeconds > 0) {
        final darkRedPaint = Paint()
          ..color = const Color(0xFFFF5252)
          ..style = PaintingStyle.fill;

        final path = Path();
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          extraAngle,
          false,
        );
        path.lineTo(center.dx, center.dy);
        path.close();

        canvas.drawPath(path, darkRedPaint);
      }
    }

    // Draw outer border
    final circlePaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, circlePaint);

    // Draw hour markers
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (pi / 180);
      final x1 = center.dx + (radius - 20) * cos(angle - pi / 2);
      final y1 = center.dy + (radius - 20) * sin(angle - pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: i == 0 ? '12' : i.toString(),
          style: const TextStyle(
            color: Color(0xFFFF9800),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x1 - textPainter.width / 2, y1 - textPainter.height / 2),
      );
    }

    // Calculate clock hands
    final totalMinutes = elapsedSeconds / 60;
    final hours = (totalMinutes / 60) % 12;
    final minutes = totalMinutes % 60;

    final hourAngle = (hours * 30 + minutes * 0.5) * (pi / 180) - pi / 2;
    final minuteAngle = (minutes * 6) * (pi / 180) - pi / 2;

    // Draw hour hand
    final hourHandPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final hourHandLength = radius - 50;
    final hourHandX = center.dx + hourHandLength * cos(hourAngle);
    final hourHandY = center.dy + hourHandLength * sin(hourAngle);
    canvas.drawLine(center, Offset(hourHandX, hourHandY), hourHandPaint);

    // Draw minute hand
    final minuteHandPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final minuteHandLength = radius - 30;
    final minuteHandX = center.dx + minuteHandLength * cos(minuteAngle);
    final minuteHandY = center.dy + minuteHandLength * sin(minuteAngle);
    canvas.drawLine(center, Offset(minuteHandX, minuteHandY), minuteHandPaint);

    // Draw center dot
    final dotPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, dotPaint);
  }

  @override
  bool shouldRepaint(TimerClockPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.color != color ||
        oldDelegate.isExtraTime != isExtraTime;
  }
}
