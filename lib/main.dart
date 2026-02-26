import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/main_layout.dart';
import 'presentation/providers/theme_provider.dart'; // Importamos el proveedor del tema

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: InkTrackApp()));
}

class InkTrackApp extends ConsumerWidget {
  const InkTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado actual del tema
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'InkTrack',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode, // ¡Aquí aplicamos la magia de Riverpod!

      // Tema Claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      // Tema Oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      home: const MainLayout(),
    );
  }
}