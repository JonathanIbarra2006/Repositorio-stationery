import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/fiado_provider.dart';

class NuevoFiadoScreen extends ConsumerStatefulWidget {
  const NuevoFiadoScreen({super.key});

  @override
  ConsumerState<NuevoFiadoScreen> createState() => _NuevoFiadoScreenState();
}

class _NuevoFiadoScreenState extends ConsumerState<NuevoFiadoScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- LÓGICA DE CLIENTE ---
  String? _clienteSeleccionadoId;
  bool _esNuevoCliente = false;

  String _nuevoNombre = '';
  String _nuevoTelefono = '';

  // --- LÓGICA DE PRODUCTOS ---
  Product? _prodSeleccionado;
  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');
  final Map<Product, int> _carrito = {};

  double get _totalDeuda {
    double total = 0;
    _carrito.forEach((p, c) => total += p.precio * c);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final clientesAsync = ref.watch(clientesProvider);
    final productosAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        Text('Registrar Fiado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        const Text('CRÉDITO Y CARTERA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1.2)),
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
                    _SectionLabel('1. ¿A QUIÉN SE LE FÍA?', Colors.orange),
                    const SizedBox(height: 12),
                    _InputCard(
                      cardColor: cardColor,
                      isDark: isDark,
                      child: clientesAsync.when(
                        loading: () => const LinearProgressIndicator(color: Colors.orange),
                        error: (e, _) => const Text('Error al cargar clientes'),
                        data: (clientes) {
                          return DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Seleccionar o Crear Cliente', Icons.person_outline_rounded, Colors.orange, isDark),
                            dropdownColor: cardColor,
                            initialValue: _clienteSeleccionadoId,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: 'NUEVO',
                                child: Row(children: [
                                  Icon(Icons.person_add_rounded, color: Colors.blue, size: 20),
                                  SizedBox(width: 12),
                                  Text('CREAR NUEVO CLIENTE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                                ]),
                              ),
                              ...clientes.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombre),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _clienteSeleccionadoId = val;
                                _esNuevoCliente = (val == 'NUEVO');
                              });
                            },
                            validator: (val) => val == null ? 'Debes seleccionar un cliente' : null,
                          );
                        },
                      ),
                    ),

                    if (_esNuevoCliente) ...[
                      const SizedBox(height: 16),
                      _InputCard(
                        cardColor: cardColor,
                        isDark: isDark,
                        child: TextFormField(
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          decoration: _inputDecoration('Nombre Completo *', Icons.person_rounded, Colors.orange, isDark),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _esNuevoCliente && (v == null || v.isEmpty) ? 'Escribe el nombre' : null,
                          onSaved: (v) => _nuevoNombre = v!.trim(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InputCard(
                        cardColor: cardColor,
                        isDark: isDark,
                        child: TextFormField(
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          decoration: _inputDecoration('Teléfono *', Icons.phone_android_rounded, Colors.orange, isDark),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => _esNuevoCliente && (v == null || v.length < 10) ? 'Mínimo 10 números' : null,
                          onSaved: (v) => _nuevoTelefono = v!.trim(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    _SectionLabel('2. PRODUCTOS A FIAR', Colors.orange),
                    const SizedBox(height: 12),

                    productosAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text('Error: $e'),
                      data: (productos) {
                        return Column(
                          children: [
                            _InputCard(
                              cardColor: cardColor,
                              isDark: isDark,
                              child: DropdownButtonFormField<Product>(
                                decoration: _inputDecoration('Producto', Icons.inventory_2_outlined, Colors.orange, isDark),
                                dropdownColor: cardColor,
                                initialValue: _prodSeleccionado,
                                isExpanded: true,
                                style: TextStyle(color: textColor, fontSize: 16),
                                items: productos.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.nombre} (${p.stock})', overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (val) => setState(() => _prodSeleccionado = val),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _InputCard(
                                    cardColor: cardColor,
                                    isDark: isDark,
                                    child: TextFormField(
                                      controller: _cantidadCtrl,
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                      decoration: _inputDecoration('Cantidad', Icons.numbers_rounded, Colors.orange, isDark),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                                    onPressed: _prodSeleccionado == null ? null : () {
                                      final cant = int.tryParse(_cantidadCtrl.text) ?? 1;
                                      if (cant <= 0) return;
                                      if (cant > _prodSeleccionado!.stock) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡No hay suficiente stock!'), backgroundColor: Colors.red));
                                        return;
                                      }
                                      setState(() {
                                        if (_carrito.containsKey(_prodSeleccionado)) {
                                          _carrito[_prodSeleccionado!] = _carrito[_prodSeleccionado!]! + cant;
                                        } else {
                                          _carrito[_prodSeleccionado!] = cant;
                                        }
                                        _prodSeleccionado = null;
                                        _cantidadCtrl.text = '1';
                                      });
                                    },
                                  ),
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    if (_carrito.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...List.generate(_carrito.length, (i) {
                        final p = _carrito.keys.elementAt(i);
                        final c = _carrito[p]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('$c', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ),
                            title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            subtitle: Text(currency.format(p.precio * c), style: TextStyle(color: subColor)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => setState(() => _carrito.remove(p)),
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL DEUDA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1)),
                          Text(currency.format(_totalDeuda), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        onPressed: _guardar,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded),
                            const SizedBox(width: 12),
                            Text(
                              _esNuevoCliente ? 'GUARDAR CLIENTE Y DEUDA' : 'CONFIRMAR DEUDA',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor complete los datos del cliente'), backgroundColor: Colors.red));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Debes agregar al menos un producto!'), backgroundColor: Colors.orange));
      return;
    }
    _formKey.currentState!.save();
    final String? idViejo = _esNuevoCliente ? null : _clienteSeleccionadoId;
    await ref.read(clientesProvider.notifier).registrarFiado(
      clienteIdExistente: idViejo,
      nombreNuevo: _nuevoNombre,
      telefonoNuevo: _nuevoTelefono,
      carrito: _carrito,
      totalDeuda: _totalDeuda,
    );
    ref.invalidate(productsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado exitoso!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
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