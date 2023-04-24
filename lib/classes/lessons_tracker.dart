// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';

const String _pending = 'pending';
const String _completed = 'completed';

class LessonTracker {
  static _LessonTotal lessons = _LessonTotal({_pending: 0, _completed: 0});
}

class _LessonTotal extends ValueNotifier {
  _LessonTotal(Map<String, int> super.value);

  setPending(int pending) {
    value[_pending] = pending;
    super.notifyListeners();
  }

  setCompleted(int completed) {
    value[_completed] = completed;
    super.notifyListeners();
  }

  resetValues() {
    value = {_pending: 0, _completed: 0};
  }

  getPending() => value[_pending].toString();

  getCompleted() => value[_completed].toString();
}
