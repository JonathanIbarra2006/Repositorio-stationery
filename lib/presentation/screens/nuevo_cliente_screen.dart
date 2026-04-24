import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/fiado_provider.dart';

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

  static const Color _accentColor = Color(0xFFEF4063);

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
        // Para registrar un nuevo cliente sin fiado inicial,
        // necesitamos un método en el notifier o hacerlo directo aquí.
        // Como ClientesNotifier no tiene un método 'addCliente' simple, lo crearemos.
        await ref.read(clientesProvider.notifier).registrarNuevoClienteDirecto(
          nombre,
          telefono,
          email,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionLabel('Información Personal', subColor),
            _InputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _nombreCtrl,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                decoration: _hint('Nombre completo *', subColor, icon: Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
            ),
            const SizedBox(height: 12),
            _InputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _telefonoCtrl,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                decoration: _hint('Teléfono / WhatsApp *', subColor, icon: Icons.phone_android_outlined),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v == null || v.length < 10 ? 'Mínimo 10 dígitos' : null,
              ),
            ),
            const SizedBox(height: 12),
            _InputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _emailCtrl,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                decoration: _hint('Correo electrónico (Opcional)', subColor, icon: Icons.email_outlined),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                onPressed: _guardarCliente,
                child: Text(
                  _esEdicion ? 'Actualizar cliente' : 'Guardar cliente',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _hint(String hint, Color subColor, {required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: subColor),
      prefixIcon: Icon(icon, color: subColor, size: 20),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  const _InputCard({required this.child, required this.cardColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
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
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
