import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/cliente_fiado.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cliente_provider.dart';
import '../providers/fiado_provider.dart';
import 'package:flutter/services.dart'; // Necesario para restringir el teclado a solo números

class NuevoFiadoScreen extends ConsumerStatefulWidget {
  const NuevoFiadoScreen({super.key});

  @override
  ConsumerState<NuevoFiadoScreen> createState() => _NuevoFiadoScreenState();
}

class _NuevoFiadoScreenState extends ConsumerState<NuevoFiadoScreen> {
  Cliente? _clienteSeleccionado;
  final Map<Product, int> _carrito = {}; // Producto y su cantidad

  double get _totalCarrito {
    double total = 0;
    _carrito.forEach((prod, cant) => total += prod.precio * cant);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productsProvider);
    final clientesAsync = ref.watch(clientesProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Deuda / Fiado')),
      body: Column(
        children: [
          // --- SELECCIÓN DE CLIENTE (HU03) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: clientesAsync.when(
                    data: (clientes) => DropdownButtonFormField<Cliente>(
                      decoration: const InputDecoration(labelText: 'Seleccionar Cliente', border: OutlineInputBorder()),
                      initialValue: _clienteSeleccionado,
                      items: clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                      onChanged: (val) => setState(() => _clienteSeleccionado = val),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('Error al cargar clientes'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  onPressed: () => _mostrarDialogoNuevoCliente(context, ref),
                  tooltip: 'Crear cliente nuevo',
                )
              ],
            ),
          ),

          // --- LISTA DE PRODUCTOS PARA AGREGAR ---
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Inventario (Toca para agregar a la cuenta)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: productosAsync.when(
              data: (productos) => ListView.builder(
                itemCount: productos.length,
                itemBuilder: (ctx, i) {
                  final p = productos[i];
                  final cantidadEnCarrito = _carrito[p] ?? 0;
                  final sinStock = (p.stock - cantidadEnCarrito) <= 0;

                  return ListTile(
                    title: Text(p.nombre),
                    subtitle: Text('Stock disp: ${p.stock - cantidadEnCarrito} | ${currency.format(p.precio)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.add_shopping_cart, color: sinStock ? Colors.grey : Colors.orange),
                      onPressed: sinStock ? null : () {
                        setState(() {
                          _carrito[p] = cantidadEnCarrito + 1;
                        });
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),

      // --- BARRA INFERIOR DE GUARDADO ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -3))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fiado:', style: TextStyle(color: Colors.grey)),
                  Text(currency.format(_totalCarrito), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                icon: const Icon(Icons.save),
                label: const Text('Guardar Deuda', style: TextStyle(fontSize: 16)),
                onPressed: (_carrito.isEmpty || _clienteSeleccionado == null) ? null : () async {

                  // Preparamos los datos
                  final items = _carrito.entries.map((e) => {
                    'productoId': e.key.id,
                    'cantidad': e.value,
                    'precio': e.key.precio,
                  }).toList();

                  // Ejecutamos la transacción en BD
                  await ref.read(fiadoRepoProvider).registrarNuevoFiado(_clienteSeleccionado!.id, items);

                  if (context.mounted) {
                    // Refrescamos las pantallas afectadas
                    ref.invalidate(deudoresProvider);
                    ref.invalidate(productsProvider); // Para actualizar el stock visualmente

                    Navigator.pop(context); // Volvemos a la pantalla anterior
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiado registrado correctamente'), backgroundColor: Colors.green));
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  // Dialog para crear cliente rápido (HU03 - Escenario 2)
  void _mostrarDialogoNuevoCliente(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>(); // Agregamos un FormKey para validar
    String nombre = '';
    String telefono = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        // SOLUCIÓN: Agregamos el Scroll aquí también por si el celular es pequeño
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ... (Los campos de Nombre y Teléfono siguen igual)
                // Validación de Nombre (Solo letras y espacios, obligatorio)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]'))],
                  validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
                  onSaved: (val) => nombre = val!,
                ),
                const SizedBox(height: 10),
                // Validación de Teléfono (Solo números, obligatorio, longitud mínima)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono (Obligatorio)', prefixText: '+57 '),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // ¡Bloquea letras!
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'El teléfono es obligatorio';
                    if (val.length < 7) return 'Ingrese un teléfono válido (Mín. 7 dígitos)';
                    return null;
                  },
                  onSaved: (val) => telefono = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final nuevo = await ref.read(fiadoRepoProvider).crearCliente(nombre.trim(), telefono);
                ref.invalidate(clientesProvider);
                if (ctx.mounted) {
                  setState(() => _clienteSeleccionado = nuevo);
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }
}