import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/proveedor.dart';
import '../providers/proveedor_provider.dart';
import '../theme/app_colors.dart';

class NuevoProveedorScreen extends ConsumerStatefulWidget {
  final Proveedor? proveedorAEditar;

  const NuevoProveedorScreen({super.key, this.proveedorAEditar});

  @override
  ConsumerState<NuevoProveedorScreen> createState() => _NuevoProveedorScreenState();
}

class _NuevoProveedorScreenState extends ConsumerState<NuevoProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  
  final List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  
  Set<String> _diasSeleccionados = {};

  bool get _esEdicion => widget.proveedorAEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedorAEditar;
    _nombreCtrl = TextEditingController(text: p?.empresa ?? '');
    
    String tel = '';
    if (p != null) {
      tel = p.contacto.split(' | ')[0];
    }
    _telefonoCtrl = TextEditingController(text: tel);
    
    if (p?.diasVisita != null && p!.diasVisita!.isNotEmpty) {
      _diasSeleccionados = p.diasVisita!.split(', ').toSet();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _toggleDia(String dia) {
    setState(() {
      if (_diasSeleccionados.contains(dia)) {
        _diasSeleccionados.remove(dia);
      } else {
        _diasSeleccionados.add(dia);
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione al menos 1 día de visita'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final diasVisitaStr = _diasSeleccionados.isEmpty 
        ? null 
        : _diasSeleccionados.toList().join(', ');

    final prov = Proveedor(
      id: _esEdicion ? widget.proveedorAEditar!.id : const Uuid().v4(),
      empresa: _nombreCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(), // We use the same for simplicity as per mockup
      contacto: _telefonoCtrl.text.trim(),
      diasVisita: diasVisitaStr,
    );

    if (_esEdicion) {
      await ref.read(proveedoresProvider.notifier).updateProveedor(prov);
    } else {
      await ref.read(proveedoresProvider.notifier).addProveedor(prov);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _buildFieldLabel('Nombre', subColor),
            _buildInputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _nombreCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Nombre de la empresa'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Teléfono', subColor),
            _buildInputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _telefonoCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('Número de contacto'),
                validator: (v) => v == null || v.length < 10 ? 'Mínimo 10 dígitos' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('10 dígitos sin espacios', style: TextStyle(color: subColor, fontSize: 12)),
            ),
            const SizedBox(height: 32),
            _buildFieldLabel('Días de visita', subColor),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _diasSemana.map((dia) {
                final isSelected = _diasSeleccionados.contains(dia);
                return GestureDetector(
                  onTap: () => _toggleDia(dia),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEBB159) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFEBB159) : Colors.black87,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          dia,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _esEdicion ? 'Actualizar' : 'Guardar',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInputCard({required Widget child, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
