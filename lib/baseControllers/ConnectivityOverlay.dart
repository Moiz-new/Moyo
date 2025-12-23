// connectivity_overlay.dart
import 'package:flutter/material.dart';
import '../constants/colorConstant/color_constant.dart';
import 'ConnectivityService.dart';

class ConnectivityOverlay extends StatefulWidget {
  final Widget child;

  const ConnectivityOverlay({super.key, required this.child});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.initialize();
  }

  @override
  void dispose() {
    ConnectivityService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.connectivityStream,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Stack(
          children: [
            // Your normal app content
            widget.child,

            // Full screen overlay when offline
            if (!isOnline)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ColorConstant.moyoScaffoldGradientLight,
                        ColorConstant.moyoScaffoldGradient,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon circle
                          Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              color: ColorConstant.moyoOrangeFade,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: ColorConstant.moyoOrange,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          const Text(
                            'You are offline',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ColorConstant.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            'Please check your internet connection.\n'
                            'We will automatically reconnect when you are back online.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6C6C6C),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Try again button (just re-triggers check)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // manually trigger a check
                                ConnectivityService.instance.initialize();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.moyoOrange,
                                foregroundColor: ColorConstant.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Try again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Hint text
                          const Text(
                            'Wi‑Fi or Mobile Data required to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
