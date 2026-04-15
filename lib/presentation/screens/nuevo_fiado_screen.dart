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
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final clientesAsync = ref.watch(clientesProvider);
    final productosAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Registrar Fiado', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------
              // SECCIÓN 1: SELECCIÓN DE CLIENTE
              // ---------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. ¿A quién se le fía?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    const SizedBox(height: 10),

                    clientesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const Text('Error al cargar clientes'),
                      data: (clientes) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: 'Seleccionar o Crear Cliente',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white
                          ),
                          initialValue: _clienteSeleccionadoId,
                          isExpanded: true,
                          items: [
                            // Opción especial para crear nuevo (AL PRINCIPIO PARA QUE SE VEA)
                            const DropdownMenuItem(
                              value: 'NUEVO',
                              child: Row(children: [
                                Icon(Icons.person_add, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('CREAR NUEVO CLIENTE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                              ]),
                            ),
                            // Lista de clientes existentes
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

                    // FORMULARIO PARA NUEVO CLIENTE
                    if (_esNuevoCliente) ...[
                      const SizedBox(height: 15),
                      const Text('Datos del Nuevo Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('(Se guardará automáticamente al confirmar la deuda)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 5),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Nombre Completo *',
                            prefixIcon: Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder()
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => _esNuevoCliente && (v == null || v.isEmpty) ? 'Escribe el nombre' : null,
                        onSaved: (v) => _nuevoNombre = v!.trim(),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Teléfono *',
                            prefixIcon: Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder()
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => _esNuevoCliente && (v == null || v.length < 7) ? 'Mínimo 7 números' : null,
                        onSaved: (v) => _nuevoTelefono = v!.trim(),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------------------------------------
              // SECCIÓN 2: PRODUCTOS
              // ---------------------------------------------------------
              const Text('2. Productos a Fiar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 10),

              productosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (productos) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: DropdownButtonFormField<Product>(
                          decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder()),
                          initialValue: _prodSeleccionado,
                          isExpanded: true,
                          items: productos.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.nombre} (${p.stock})', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) => setState(() => _prodSeleccionado = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cantidadCtrl,
                          decoration: const InputDecoration(labelText: 'Cant.', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add),
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
                      )
                    ],
                  );
                },
              ),

              // LISTA DEL CARRITO
              if (_carrito.isNotEmpty) ...[
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _carrito.length,
                  itemBuilder: (ctx, i) {
                    final p = _carrito.keys.elementAt(i);
                    final c = _carrito[p]!;
                    return Card(
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Text('$c')),
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Total: ${currency.format(p.precio * c)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _carrito.remove(p)),
                        ),
                      ),
                    );
                  },
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('Agrega productos para continuar...', style: TextStyle(color: Colors.grey))),
                ),

              const SizedBox(height: 20),

              // ---------------------------------------------------------
              // SECCIÓN 3: BOTÓN DE CONFIRMAR (SIEMPRE VISIBLE)
              // ---------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL DEUDA:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(currency.format(_totalDeuda), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Verde para indicar éxito
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: const Icon(Icons.save),
                  // CAMBIO CLAVE: El texto explica que se guarda todo
                  label: Text(
                      _esNuevoCliente ? 'GUARDAR CLIENTE Y DEUDA' : 'CONFIRMAR DEUDA',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  // CAMBIO CLAVE: Siempre activo para validar al presionar
                  onPressed: _guardar,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    // 1. Validar formulario (Cliente)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor complete los datos del cliente'), backgroundColor: Colors.red));
      return;
    }

    // 2. Validar Carrito (Productos)
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Debes agregar al menos un producto!'), backgroundColor: Colors.orange));
      return;
    }

    // 3. Todo OK -> Guardar
    _formKey.currentState!.save();
    final String? idViejo = _esNuevoCliente ? null : _clienteSeleccionadoId;

    await ref.read(clientesProvider.notifier).registrarFiado(
      clienteIdExistente: idViejo,
      nombreNuevo: _nuevoNombre,
      telefonoNuevo: _nuevoTelefono,
      carrito: _carrito,
      totalDeuda: _totalDeuda,
    );

    ref.invalidate(productsProvider); // Actualizar inventario

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado exitoso!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }
}