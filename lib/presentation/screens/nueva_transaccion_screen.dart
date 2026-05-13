import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

class NuevaTransaccionScreen extends ConsumerStatefulWidget {
  final TransactionType tipo;

  const NuevaTransaccionScreen({super.key, required this.tipo});

  @override
  ConsumerState<NuevaTransaccionScreen> createState() => _NuevaTransaccionScreenState();
}

class _NuevaTransaccionScreenState extends ConsumerState<NuevaTransaccionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _montoCtrl;
  late final TextEditingController _descripcionCtrl;
  late String _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _categoriaSeleccionada = widget.tipo == TransactionType.ingreso ? 'Ventas Extra' : 'Servicios';
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  final List<String> _categoriasIngreso = ['Ventas Extra', 'Aporte Capital', 'Préstamo', 'Otros'];
  final List<String> _categoriasGasto = ['Servicios', 'Arriendo', 'Nómina', 'Proveedores', 'Mantenimiento', 'Otros'];

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = AppTransaction(
      id: const Uuid().v4(),
      tipo: widget.tipo,
      monto: double.tryParse(_montoCtrl.text.trim()) ?? 0.0,
      fecha: DateTime.now(),
      descripcion: _descripcionCtrl.text.trim(),
      categoria: _categoriaSeleccionada,
    );

    try {
      await ref.read(transactionsProvider.notifier).addTransaction(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción guardada correctamente'), backgroundColor: kSuccess),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    
    final colorPrincipal = widget.tipo == TransactionType.ingreso ? kSuccess : kError;
    final titulo = widget.tipo == TransactionType.ingreso ? 'Nuevo Ingreso' : 'Nuevo Egreso';
    final subTitulo = widget.tipo == TransactionType.ingreso ? 'ENTRADA DE DINERO' : 'SALIDA DE DINERO';
    final categorias = widget.tipo == TransactionType.ingreso ? _categoriasIngreso : _categoriasGasto;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(subTitulo, style: TextStyle(fontSize: 10, color: colorPrincipal, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('DATOS DE LA OPERACIÓN'),
              
              _buildTextField(
                controller: _montoCtrl,
                label: 'Monto *',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                accentColor: colorPrincipal,
              ),
              
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _descripcionCtrl,
                label: 'Descripción *',
                icon: Icons.description_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                accentColor: kAccent,
              ),
              
              const SizedBox(height: 20),
              
              _buildDropdown(
                label: 'Categoría *',
                icon: Icons.category_outlined,
                value: _categoriaSeleccionada,
                items: categorias,
                onChanged: (v) => setState(() => _categoriaSeleccionada = v!),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('GUARDAR TRANSACCIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: colorPrincipal.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(title, 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kNavyLighter : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : kNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: accentColor),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kNavyLighter : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : kNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kAccent),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
        dropdownColor: isDark ? kNavyLighter : Colors.white,
      ),
    );
  }
}
