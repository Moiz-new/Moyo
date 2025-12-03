import 'package:flutter/cupertino.dart';

class UserNavigationProvider extends ChangeNotifier {
  int currentIndex = 0;
  bool isProvider = false;

  setCurrentIndex(int newIndex) {
    currentIndex = newIndex;
    notifyListeners();
  }
}
