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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Seleccione al menos 1 día de visita'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final diasVisitaStr = _diasSeleccionados.toList().join(', ');

    final prov = Proveedor(
      id: _esEdicion ? widget.proveedorAEditar!.id : const Uuid().v4(),
      empresa: _nombreCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(), 
      contacto: _telefonoCtrl.text.trim(),
      diasVisita: diasVisitaStr,
    );

    try {
      if (_esEdicion) {
        await ref.read(proveedoresProvider.notifier).updateProveedor(prov);
      } else {
        await ref.read(proveedoresProvider.notifier).addProveedor(prov);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(_esEdicion ? 'Proveedor actualizado' : 'Proveedor guardado correctamente'),
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
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header similar to other screens
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
                          _esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        Text(
                          'GESTIÓN DE SUMINISTROS',
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
                  const SizedBox(width: 48), 
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
                    const _SectionLabel('INFORMACIÓN DEL PROVEEDOR', kAccent),
                    const SizedBox(height: 12),
                    _InputCard(
                      cardColor: cardColor,
                      isDark: isDark,
                      child: TextFormField(
                        controller: _nombreCtrl,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('Nombre de la Empresa *', Icons.business_rounded, kAccent, isDark),
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
                    
                    const SizedBox(height: 32),
                    const _SectionLabel('DÍAS DE VISITA / PEDIDO', kAccent),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: _diasSemana.map((dia) {
                        final isSelected = _diasSeleccionados.contains(dia);
                        return GestureDetector(
                          onTap: () => _toggleDia(dia),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? kAccent : cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? kAccent : (isDark ? Colors.white10 : Colors.grey.shade300),
                                width: 1.5,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: kAccent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  dia,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 48),
                    
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
                        onPressed: _guardar,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_esEdicion ? Icons.update_rounded : Icons.save_rounded),
                            const SizedBox(width: 12),
                            Text(
                              _esEdicion ? 'ACTUALIZAR PROVEEDOR' : 'GUARDAR PROVEEDOR',
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
