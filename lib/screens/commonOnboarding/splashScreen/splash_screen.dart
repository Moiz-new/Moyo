// splash_screen.dart
import 'package:first_flutter/screens/commonOnboarding/splashScreen/splash_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _initializeVideo();

    // Set a 3-second timer to navigate
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final provider = Provider.of<SplashProvider>(context, listen: false);
        provider.initializeSplash((String route) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, route);
          }
        });
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/moyosplash.mp4');
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _videoController!.setLooping(false);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isVideoInitialized && _videoController != null
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          : Center(
              child: Image.asset(
                "assets/icons/app_icon_radius.png.png",
                width: 150,
                height: 150,
              ),
            ),
    );
  }
}
