import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';

class PdfGenerator {
  // -----------------------------------------------------------------
  // 1. GENERAR RECIBO DE VENTA (Ticket)
  // -----------------------------------------------------------------
  static Future<void> generateReceipt(Map<Product, int> carrito, double total) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato tipo Ticket de compra
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('INKTRACK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20))),
              pw.Center(child: pw.Text('Comprobante de Venta')),
              pw.Divider(),
              pw.Text('Fecha: $fecha'),
              pw.Divider(),

              // Lista de Productos
              ...carrito.entries.map((e) {
                final p = e.key;
                final cant = e.value;
                final subtotal = p.precio * cant;
                return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${cant}x ${p.nombre}', style: const pw.TextStyle(fontSize: 10))),
                      pw.Text(currency.format(subtotal), style: const pw.TextStyle(fontSize: 10)),
                    ]
                );
              }),

              pw.Divider(),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(currency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('¡Gracias por su compra!', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Recibo_InkTrack_$fecha',
    );
  }

  // -----------------------------------------------------------------
  // 2. GENERAR REPORTE DE FINANZAS (Hoja Carta)
  // -----------------------------------------------------------------
  static Future<void> generateFinanceReport(List<AppTransaction> transacciones) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Calculamos totales
    double ingresos = 0;
    double gastos = 0;
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
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Reporte Financiero - InkTrack', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      pw.Text('Generado: $fecha'),
                    ]
                )
            ),
            pw.SizedBox(height: 20),

            // Resumen
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResumenCard('Ingresos', ingresos, PdfColors.green),
                  _buildResumenCard('Gastos', gastos, PdfColors.red),
                  _buildResumenCard('Balance', balance, balance >= 0 ? PdfColors.blue : PdfColors.red),
                ]
            ),
            pw.SizedBox(height: 20),

            // Tabla de Movimientos
            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Tipo', 'Descripción', 'Monto'],
              data: transacciones.map((t) => [
                DateFormat('dd/MM/yy').format(t.fecha),
                t.tipo.name.toUpperCase(),
                t.descripcion,
                currency.format(t.monto)
              ]).toList(),
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reporte_Financiero_$fecha',
    );
  }

  static pw.Widget _buildResumenCard(String title, double amount, PdfColor color) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color),
            borderRadius: pw.BorderRadius.circular(5)
        ),
        child: pw.Column(
            children: [
              pw.Text(title, style: pw.TextStyle(color: color)),
              pw.Text(currency.format(amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ]
        )
    );
  }
}
