import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';

class PdfService {
  static Future<void> generarYCompartirReporteCaja(List<AppTransaction> transacciones, double ingresos, double gastos, double balance) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final fechaHoy = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Dibujamos la página del PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Text('InkTrack - Reporte de Caja', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Fecha de generación: $fechaHoy', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 20),

              // Resumen de Totales
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildTotalesPDF('Ingresos', currency.format(ingresos), PdfColors.green),
                    _buildTotalesPDF('Gastos', currency.format(gastos), PdfColors.red),
                    _buildTotalesPDF('Balance', currency.format(balance), PdfColors.blue),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabla de Transacciones
              pw.Text('Detalle de Movimientos:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Fecha', 'Tipo', 'Categoría', 'Descripción', 'Monto'],
                data: transacciones.map((t) {
                  return [
                    DateFormat('dd/MM/yy HH:mm').format(t.fecha),
                    t.tipo == TransactionType.ingreso ? 'Ingreso' : 'Gasto',
                    t.categoria ?? 'N/A',
                    t.descripcion,
                    currency.format(t.monto),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF temporalmente en el dispositivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Reporte_Caja_InkTrack.pdf');
    await file.writeAsBytes(await pdf.save());

    // Compartir o abrir el archivo
    await Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes el reporte financiero de InkTrack.');
  }

  // Widget auxiliar para el PDF
  static pw.Widget _buildTotalesPDF(String titulo, String valor, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(titulo, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(valor, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}