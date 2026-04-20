import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateRangeState {
  final DateTimeRange? range;
  final String label;

  DateRangeState({this.range, required this.label});
}

class DateRangeNotifier extends StateNotifier<DateRangeState> {
  DateRangeNotifier() : super(_getInitialState());

  static DateRangeState _getInitialState() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateRangeState(
      range: DateTimeRange(start: today, end: today),
      label: 'Hoy',
    );
  }

  void setRange(DateTimeRange? range, String label) {
    state = DateRangeState(range: range, label: label);
  }

  void reset() {
    state = DateRangeState(range: null, label: 'Hoy');
  }
}

final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRangeState>((ref) {
  return DateRangeNotifier();
});
