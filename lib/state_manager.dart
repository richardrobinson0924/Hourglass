import 'package:flutter/foundation.dart';

/// A state manager, controlled by index.
class Manager<T extends MyStep> {
  final List<T> _steps;
  var _currentIndex;

  int get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;

    for (var i = 0; i < _steps.length; i += 1) {
      if (i <  currentIndex) _steps[i].onStepIsComplete();

      if (i == currentIndex) _steps[i].onStepIsCurrent();

      if (i >  currentIndex) _steps[i].onStepIsUpcoming();
    }
  }

  Manager({@required Iterable<T> steps}) : _steps = steps.toList() {
    currentIndex = 0;
  }

  T operator [](int index) => _steps[index];
}

abstract class MyStep {
  /// This method will execute once the step is complete
  void onStepIsComplete();

  /// This method will execute once the step is in progress
  void onStepIsCurrent();

  /// This method will execute once the step is in the future
  void onStepIsUpcoming();
}