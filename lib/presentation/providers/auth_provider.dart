import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Excepciones de autenticación tipadas
// ──────────────────────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  final AuthErrorType type;

  const AuthException(this.message, {this.type = AuthErrorType.unknown});

  @override
  String toString() => message;
}

enum AuthErrorType {
  emailAlreadyExists,
  invalidCredentials,
  weakPassword,
  invalidEmail,
  networkError,
  tooManyRequests,
  unknown,
}

// ──────────────────────────────────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(Supabase.instance.client.auth.currentUser) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  /// Mapea errores de Supabase a excepciones legibles en español.
  AuthException _mapError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('user already registered') ||
        msg.contains('email address is already registered') ||
        msg.contains('already been registered') ||
        msg.contains('email already in use') ||
        msg.contains('email_address_not_authorized') ||
        msg.contains('unique constraint') ||
        (e is AuthApiException && (e.statusCode == '422' || e.statusCode == '409'))) {
      return const AuthException(
        'Cuenta ya existente',
        type: AuthErrorType.emailAlreadyExists,
      );
    }

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password') ||
        (e is AuthApiException && e.statusCode == '400')) {
      return const AuthException(
        'Correo o contraseña incorrectos',
        type: AuthErrorType.invalidCredentials,
      );
    }

    if (msg.contains('password should be at least') ||
        msg.contains('weak password')) {
      return const AuthException(
        'La contraseña no cumple los requisitos mínimos',
        type: AuthErrorType.weakPassword,
      );
    }

    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email')) {
      return const AuthException(
        'El correo electrónico no es válido',
        type: AuthErrorType.invalidEmail,
      );
    }

    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return const AuthException(
        'Sin conexión a internet. Verifica tu red.',
        type: AuthErrorType.networkError,
      );
    }

    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return const AuthException(
        'Demasiados intentos. Espera unos minutos.',
        type: AuthErrorType.tooManyRequests,
      );
    }

    return AuthException(
      'Error inesperado. Inténtalo de nuevo.',
      type: AuthErrorType.unknown,
    );
  }

  Future<void> signIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Supabase a veces retorna usuario existente sin lanzar error.
      // Si el usuario ya existía, identityData suele estar vacío o
      // el campo email_confirmed_at ya tiene valor (cuenta preexistente).
      final user = response.user;
      if (user != null &&
          user.identities != null &&
          user.identities!.isEmpty) {
        throw const AuthException(
          'Cuenta ya existente',
          type: AuthErrorType.emailAlreadyExists,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw _mapError(e);
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  bool get isAuthenticated => state != null;
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
