import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';

class NuevoClienteScreen extends ConsumerStatefulWidget {
  final Cliente? clienteAEditar;

  const NuevoClienteScreen({super.key, this.clienteAEditar});

  @override
  ConsumerState<NuevoClienteScreen> createState() => _NuevoClienteScreenState();
}

class _NuevoClienteScreenState extends ConsumerState<NuevoClienteScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;

  bool get _esEdicion => widget.clienteAEditar != null;

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    final c = widget.clienteAEditar;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();

    try {
      if (_esEdicion) {
        await ref.read(clientesProvider.notifier).editarCliente(
              widget.clienteAEditar!.id,
              nombre,
              telefono,
              email,
            );
      } else {
        await ref.read(clientesProvider.notifier).registrarNuevoClienteDirecto(
          nombre,
          telefono,
          email,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(_esEdicion ? 'Cliente actualizado' : 'Cliente guardado correctamente'),
              ],
            ),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'), 
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header similar to VentaDeContado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        Text(
                          'GESTIÓN DE CLIENTES',
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: kAccent, 
                            letterSpacing: 1.2
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Placeholder for symmetry
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SectionLabel('INFORMACIÓN PERSONAL', kAccent),
                    const SizedBox(height: 12),
                    _InputCard(
                      cardColor: cardColor,
                      isDark: isDark,
                      child: TextFormField(
                        controller: _nombreCtrl,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('Nombre completo *', Icons.person_outline_rounded, kAccent, isDark),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InputCard(
                      cardColor: cardColor,
                      isDark: isDark,
                      child: TextFormField(
                        controller: _telefonoCtrl,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('WhatsApp / Teléfono *', Icons.phone_android_rounded, kAccent, isDark),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => v == null || v.length < 10 ? 'Mínimo 10 dígitos' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InputCard(
                      cardColor: cardColor,
                      isDark: isDark,
                      child: TextFormField(
                        controller: _emailCtrl,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('Correo electrónico (Opcional)', Icons.alternate_email_rounded, kAccent, isDark),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!_emailRegex.hasMatch(v.trim())) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kAccent.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        onPressed: _guardarCliente,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_esEdicion ? Icons.update_rounded : Icons.save_rounded),
                            const SizedBox(width: 12),
                            Text(
                              _esEdicion ? 'ACTUALIZAR CLIENTE' : 'GUARDAR CLIENTE',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color accentColor, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accentColor, size: 22),
      filled: true,
      fillColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : Colors.grey.shade600, 
        fontSize: 14,
        fontWeight: FontWeight.w500
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  final bool isDark;
  const _InputCard({required this.child, required this.cardColor, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text, 
        style: TextStyle(
          color: color, 
          fontSize: 11, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.5
        )
      ),
    );
  }
}

