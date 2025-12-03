import 'package:flutter/cupertino.dart';

class ProviderNavigationProvider extends ChangeNotifier {
  int currentIndex = 0;
  bool isProvider = false;

  setCurrentIndex(int newIndex) {
    currentIndex = newIndex;
    notifyListeners();
  }
}
