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
    // Sin filtro de fecha al iniciar: se muestran TODAS las transacciones.
    // El usuario puede acotar el rango desde el calendario en la pantalla de inicio.
    return DateRangeState(range: null, label: 'Todo');
  }

  void setRange(DateTimeRange? range, String label) {
    state = DateRangeState(range: range, label: label);
  }

  /// Limpia el filtro de fecha: muestra TODAS las transacciones sin restricción.
  /// Se llama tras descargar datos de la nube para que el historial completo sea visible.
  void clearRange() {
    state = DateRangeState(range: null, label: 'Todo');
  }

  void reset() {
    state = DateRangeState(range: null, label: 'Todo');
  }
}

final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRangeState>((ref) {
  return DateRangeNotifier();
});
