import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/transaction.dart';

class ExcelGenerator {
  static Future<void> generateFinanceReport(List<AppTransaction> transacciones) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Reporte Financiero'];
    excel.delete('Sheet1'); // Eliminar la hoja por defecto

    // Estilos
    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      backgroundColorHex: ExcelColor.teal,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Cabeceras
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Tipo'),
      TextCellValue('Categoría'),
      TextCellValue('Descripción'),
      TextCellValue('Monto'),
    ]);

    // Aplicar estilo a las cabeceras
    for (int i = 0; i < 5; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    // Datos
    for (var t in transacciones) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(t.fecha)),
        TextCellValue(t.tipo.toString().split('.').last.toUpperCase()),
        TextCellValue(t.categoria ?? 'General'),
        TextCellValue(t.descripcion),
        DoubleCellValue(t.monto),
      ]);
    }

    // Auto-ajustar columnas (opcional, excel package lo maneja decentemente)
    
    final String fileName = "Reporte_Klip_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx";
    
    // Guardar y compartir
    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte Financiero Klip');
    }
  }
}
