import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/main_layout.dart';
import 'presentation/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await initializeDateFormatting('es_CO', null);
  runApp(const ProviderScope(child: KlipApp()));
}

class KlipApp extends ConsumerWidget {
  const KlipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'Klip',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: user == null ? const LoginScreen() : const MainLayout(),
    );
  }
}
