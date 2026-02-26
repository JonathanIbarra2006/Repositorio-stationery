import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fiado_provider.dart';
import '../providers/transaction_provider.dart'; // Para actualizar la caja al pagar
// Agrega esta línea:
import 'nuevo_fiado_screen.dart';
class FiadosScreen extends ConsumerWidget {
  const FiadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deudoresAsync = ref.watch(deudoresProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Fiados (Cartera)')),
      body: deudoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (deudores) {
          if (deudores.isEmpty) return const Center(child: Text('No hay clientes con deudas pendientes. ¡Excelente!'));

          return ListView.builder(
            itemCount: deudores.length,
            itemBuilder: (context, index) {
              final cliente = deudores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(cliente['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Deuda Total'),
                  trailing: Text(
                    currency.format(cliente['deuda_total']),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  onTap: () => _mostrarDialogoAbono(context, ref, cliente['id'], cliente['nombre'], cliente['deuda_total']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navega a la pantalla de Nuevo Fiado
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NuevoFiadoScreen()),
          );
        },
        icon: const Icon(Icons.post_add),
        label: const Text('Nuevo Fiado'),
      ),
    );
  }

  void _mostrarDialogoAbono(BuildContext context, WidgetRef ref, String clienteId, String nombre, double deudaTotal) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar Abono - $nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deuda actual: \$${deudaTotal.toStringAsFixed(0)}'),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto a abonar (\$)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(controller.text);
              if (monto != null && monto > 0 && monto <= deudaTotal) {
                // 1. Registramos el abono en SQLite
                await ref.read(fiadoRepoProvider).registrarAbono(clienteId, monto, nombre);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  // 2. Refrescamos la lista de deudores
                  ref.invalidate(deudoresProvider);
                  // 3. Refrescamos la caja diaria para que se vea el ingreso automáticamente
                  ref.invalidate(transactionsProvider);

                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Abono registrado con éxito. Caja actualizada.'), backgroundColor: Colors.green));
                }
              }
            },
            child: const Text('Guardar Abono'),
          )
        ],
      ),
    );
  }
}