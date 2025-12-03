import 'dart:async';

class SplashServices {
  Future<void> startSplash(Function onComplete) async {
    await Future.delayed(const Duration(seconds: 3));
    onComplete(); // callback after delay
  }
}
