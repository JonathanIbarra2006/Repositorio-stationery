import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/proveedor.dart';
import '../../presentation/providers/fiado_provider.dart'; // Para el modelo Cliente

class PdfGenerator {
  static const _klipColor = PdfColor.fromInt(0xFF00C2FF); // kAccent
  static const _darkColor = PdfColor.fromInt(0xFF0F172A);

  // =================================================================
  //  SECCIÓN DE VENTAS (FACTURA / TICKET PROFESIONAL)
  // =================================================================

  static Future<void> generateReceipt(
      Map<Product, int> carrito, double total, {String? clienteName, String? transaccionId}) async {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final doc = pw.Document();
    final reciboNum = transaccionId != null ? transaccionId.substring(0, 8).toUpperCase() : DateTime.now().millisecondsSinceEpoch.toString().substring(5);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, 
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER CORPORATIVO
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _darkColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text('KLIP', style: pw.TextStyle(color: _klipColor, fontWeight: pw.FontWeight.bold, fontSize: 24, letterSpacing: 2)),
                )
              ),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('FACTURA DE VENTA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('Nº $reciboNum', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
              pw.SizedBox(height: 10),
              
              // INFO FECHA Y CLIENTE
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fecha: $fecha', style: const pw.TextStyle(fontSize: 10)),
                    if (clienteName != null && clienteName.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Cliente: $clienteName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  ]
                )
              ),
              pw.SizedBox(height: 15),

              // TABLA DE PRODUCTOS
              pw.TableHelper.fromTextArray(
                headers: ['CANT', 'PRODUCTO', 'SUBTOTAL'],
                data: carrito.entries.map((e) {
                  final p = e.key;
                  final cant = e.value;
                  final subtotal = p.precio * cant;
                  return [cant.toString(), p.nombre, currency.format(subtotal)];
                }).toList(),
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: _darkColor),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                },
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              ),

              pw.SizedBox(height: 15),
              // TOTALES
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(currency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: _klipColor)),
                  ]
              ),
              pw.SizedBox(height: 25),
              pw.Divider(color: PdfColors.grey300, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('¡Gracias por su compra!', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Generado por Klip App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500))),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Factura_$reciboNum.pdf');
  }

  // =================================================================
  //  REPORTES GENERALES Y POR CATEGORÍAS
  // =================================================================

  static pw.Widget _buildHeader(String title) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: _klipColor)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(color: _darkColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('KLIP', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 2))
            ),
          ]
        ),
        pw.SizedBox(height: 8),
        pw.Text('Generado el: $fecha', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
        pw.SizedBox(height: 20),
      ]
    );
  }

  static pw.Widget _buildResumenCard(String title, double amount, PdfColor color) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        width: 140,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColor.fromInt(color.toInt()),
        ),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(color: color, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text(currency.format(amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ]
        )
    );
  }

  static Future<void> generateMovementsReport(List<AppTransaction> transacciones) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    double ingresos = 0, gastos = 0;
    for (var t in transacciones) {
      if (t.tipo == TransactionType.ingreso) {
        ingresos += t.monto;
      } else {
        gastos += t.monto;
      }
    }
    final balance = ingresos - gastos;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Reporte de Movimientos'),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildResumenCard('Ingresos Totales', ingresos, PdfColors.green),
                  _buildResumenCard('Gastos Totales', gastos, PdfColors.red),
                  _buildResumenCard('Balance Neto', balance, balance >= 0 ? _klipColor : PdfColors.red),
                ]
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Tipo', 'Descripción', 'Categoría', 'Monto'],
              data: transacciones.map((t) => [
                DateFormat('dd/MM/yy').format(t.fecha),
                t.tipo.toString().split('.').last.toUpperCase(),
                t.descripcion,
                t.categoria ?? 'General',
                currency.format(t.monto)
              ]).toList(),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Movimientos_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }

  static Future<void> generateInventoryReport(List<Product> products) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Reporte de Inventario'),
            pw.TableHelper.fromTextArray(
              headers: ['Código', 'Producto', 'Categoría', 'Stock', 'Mínimo', 'Precio'],
              data: products.map((p) => [
                p.codigoBarras ?? 'S/N',
                p.nombre,
                p.categoria,
                p.stock.toString(),
                p.stockMinimo.toString(),
                currency.format(p.precio)
              ]).toList(),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Inventario_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }

  static Future<void> generateClientsReport(List<Cliente> clientes) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Directorio de Clientes'),
            pw.TableHelper.fromTextArray(
              headers: ['ID', 'Cédula', 'Nombre', 'Teléfono', 'Email', 'Estado'],
              data: clientes.map((c) => [
                c.id.substring(0, 8),
                c.cedula,
                c.nombre,
                c.telefono ?? '-',
                c.email ?? '-',
                c.isActive ? 'Activo' : 'Inactivo'
              ]).toList(),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Clientes_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }

  static Future<void> generateDebtorsReport(List<Cliente> clientes, Map<String, double> deudas) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    
    double deudaTotal = 0;
    for (var v in deudas.values) {
      deudaTotal += v;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Reporte de Cartera (Clientes Fiados)'),
            _buildResumenCard('Total Por Cobrar', deudaTotal, PdfColors.orange),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Cédula', 'Cliente', 'Teléfono', 'Deuda Pendiente'],
              data: clientes.where((c) => (deudas[c.id] ?? 0) > 0).map((c) => [
                c.cedula,
                c.nombre,
                c.telefono ?? '-',
                currency.format(deudas[c.id] ?? 0)
              ]).toList(),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Cartera_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }

  static Future<void> generateProvidersReport(List<Proveedor> proveedores) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Directorio de Proveedores'),
            pw.TableHelper.fromTextArray(
              headers: ['Empresa', 'Contacto', 'Teléfono', 'Días de Visita'],
              data: proveedores.map((p) => [
                p.empresa,
                p.contacto,
                p.contacto,
                p.diasVisita ?? ''
              ]).toList(),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Proveedores_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }

  static Future<void> generateGeneralReport({
    required List<AppTransaction> transacciones,
    required List<Product> products,
    required List<Cliente> clientes,
    required Map<String, double> deudas,
    required List<Proveedor> proveedores,
  }) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    double ingresos = 0, egresos = 0;
    for (var t in transacciones) {
      if (t.tipo == TransactionType.ingreso) {
        ingresos += t.monto;
      } else {
        egresos += t.monto;
      }
    }
    double totalCartera = 0;
    for (var v in deudas.values) {
      totalCartera += v;
    }
    double valorizacionInventario = 0;
    for (var p in products) {
      valorizacionInventario += (p.precio * p.stock);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Resumen Ejecutivo General'),
            pw.Text('Resumen Financiero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildResumenCard('Ingresos Totales', ingresos, PdfColors.green),
                  _buildResumenCard('Egresos Totales', egresos, PdfColors.red),
                  _buildResumenCard('Balance Neto', ingresos - egresos, (ingresos - egresos) >= 0 ? _klipColor : PdfColors.red),
                ]
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text('Métricas del Negocio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Métrica', 'Valor'],
              data: [
                ['Total Clientes Registrados', clientes.length.toString()],
                ['Cartera Pendiente (Por Cobrar)', currency.format(totalCartera)],
                ['Valorización de Inventario', currency.format(valorizacionInventario)],
                ['Total de Proveedores', proveedores.length.toString()],
                ['Productos en Inventario', products.length.toString()],
              ],
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: _darkColor),
              cellStyle: const pw.TextStyle(fontSize: 12),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'Reporte_General_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf');
  }
}
