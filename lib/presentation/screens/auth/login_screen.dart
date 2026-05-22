import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Helpers de validación
// ──────────────────────────────────────────────────────────────────────────────

bool _isEmailValid(String email) {
  return RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

class _PasswordStrength {
  final int score; // 0..4
  final String label;
  final Color color;

  const _PasswordStrength(this.score, this.label, this.color);
}

_PasswordStrength _checkStrength(String password) {
  if (password.isEmpty) return const _PasswordStrength(0, '', Colors.transparent);

  int score = 0;
  if (password.length >= 8) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

  return switch (score) {
    1 => const _PasswordStrength(1, 'Muy débil', Color(0xFFEF4444)),
    2 => const _PasswordStrength(2, 'Débil', Color(0xFFF59E0B)),
    3 => const _PasswordStrength(3, 'Buena', Color(0xFF3B82F6)),
    4 => const _PasswordStrength(4, 'Fuerte', Color(0xFF10B981)),
    _ => const _PasswordStrength(0, 'Muy débil', Color(0xFFEF4444)),
  };
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget Principal
// ──────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  bool _isLogin = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _errorMessage = '';
  bool _isEmailAlreadyExists = false;

  // Animations
  late final AnimationController _slideController;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
      _isEmailAlreadyExists = false;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    if (!_isLogin) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  void _setError(String msg, {bool emailExists = false}) {
    setState(() {
      _errorMessage = msg;
      _isEmailAlreadyExists = emailExists;
    });
    _triggerShake();
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _errorMessage = '';
      _isEmailAlreadyExists = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ── Validaciones del lado del cliente ──
    if (email.isEmpty || password.isEmpty) {
      _setError('Por favor completa todos los campos');
      return;
    }

    if (!_isEmailValid(email)) {
      _setError('El formato del correo electrónico no es válido');
      return;
    }

    if (!_isLogin) {
      final strength = _checkStrength(password);
      if (strength.score < 4) {
        _setError(
          'La contraseña debe tener mín. 8 caracteres, mayúscula, número y carácter especial',
        );
        return;
      }

      if (password != confirmPassword) {
        _setError('Las contraseñas no coinciden');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).signIn(email, password);
      } else {
        await ref.read(authProvider.notifier).signUp(email, password);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  '¡Cuenta creada! Revisa tu correo para confirmarla.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        setState(() {
          _isLogin = true;
          _errorMessage = '';
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
        _slideController.reverse();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _setError(
        e.message,
        emailExists: e.type == AuthErrorType.emailAlreadyExists,
      );
    } catch (e) {
      if (!mounted) return;
      _setError('Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool showingPassword = isPassword ? _showPassword : _showConfirmPassword;

    return TextField(
      controller: controller,
      obscureText: (isPassword || isConfirmPassword) ? !showingPassword : false,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: !isPassword && !isConfirmPassword,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      onChanged: (_) {
        if (_errorMessage.isNotEmpty) {
          setState(() {
            _errorMessage = '';
            _isEmailAlreadyExists = false;
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(prefixIcon, color: AppColors.electricBlue, size: 20),
        suffixIcon: (isPassword || isConfirmPassword)
            ? IconButton(
                icon: Icon(
                  showingPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) {
                      _showPassword = !_showPassword;
                    } else {
                      _showConfirmPassword = !_showConfirmPassword;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    final password = _passwordController.text;
    final strength = _checkStrength(password);

    return AnimatedOpacity(
      opacity: password.isNotEmpty ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < strength.score
                        ? strength.color
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              );
            }),
          ),
          if (strength.score > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Contraseña: ${strength.label}',
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = math.sin(_shakeAnimation.value * math.pi * 4) * 6;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isEmailAlreadyExists
              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
              : AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isEmailAlreadyExists
                ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                : AppColors.error.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isEmailAlreadyExists
                  ? Icons.person_off_outlined
                  : Icons.error_outline_rounded,
              color: _isEmailAlreadyExists
                  ? const Color(0xFFF59E0B)
                  : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: _isEmailAlreadyExists
                      ? const Color(0xFFF59E0B)
                      : AppColors.error,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_isEmailAlreadyExists)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLogin = true;
                    _errorMessage = '';
                    _isEmailAlreadyExists = false;
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  });
                  _slideController.reverse();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Fondo con gradiente ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050E1A), Color(0xFF020617)],
              ),
            ),
          ),

          // ── Glow superior derecho ────────────────────────────────────────
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.electricBlue.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Glow inferior izquierdo ──────────────────────────────────────
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Cuadrícula decorativa ────────────────────────────────────────
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // ── Contenido principal ──────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // ── Logo + Nombre ──────────────────────────────────
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          height: 96,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Klip',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gestión Inteligente de Papelería',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Tarjeta glassmorphism ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Título del formulario ──────────────────
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.15),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Column(
                                  key: ValueKey(_isLogin),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLogin
                                          ? 'Bienvenido de vuelta'
                                          : 'Crear cuenta',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLogin
                                          ? 'Ingresa tus credenciales para continuar'
                                          : 'Completa el formulario para registrarte',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Banner de error / cuenta existente ─────
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                child: _buildErrorBanner(),
                              ),

                              // ── Campo: Correo ──────────────────────────
                              _buildTextField(
                                controller: _emailController,
                                label: 'Correo electrónico',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              // ── Campo: Contraseña ──────────────────────
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),

                              // ── Indicador de fortaleza (solo en registro)
                              if (!_isLogin)
                                AnimatedBuilder(
                                  animation: _passwordController,
                                  builder: (context, child) =>
                                      _buildPasswordStrengthBar(),
                                ),

                              // ── Campo: Confirmar contraseña ────────────
                              AnimatedSize(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                child: !_isLogin
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: _buildTextField(
                                          controller:
                                              _confirmPasswordController,
                                          label: 'Confirmar contraseña',
                                          prefixIcon: Icons.lock_person_outlined,
                                          isConfirmPassword: true,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 28),

                              // ── Botón principal ────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: _isLoading
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              AppColors.electricBlue,
                                              AppColors.cyan,
                                            ],
                                          ),
                                    color: _isLoading
                                        ? AppColors.electricBlue.withValues(
                                            alpha: 0.4,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: _isLoading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppColors.electricBlue
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleAuth,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            _isLogin
                                                ? 'Iniciar Sesión'
                                                : 'Crear Cuenta',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Divisor ────────────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      _isLogin
                                          ? '¿No tienes cuenta?'
                                          : '¿Ya tienes cuenta?',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ── Botón secundario ───────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.electricBlue,
                                    side: BorderSide(
                                      color: AppColors.electricBlue.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Registrarme' : 'Iniciar Sesión',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Pie de página ──────────────────────────────────
                      const SizedBox(height: 32),
                      Text(
                        'Klip © ${DateTime.now().year} · Todos los derechos reservados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Pintor decorativo de cuadrícula
// ──────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 48.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
