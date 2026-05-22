import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/product.dart';
import '../../domain/models/proveedor.dart';
import '../../presentation/providers/fiado_provider.dart'; // Para el modelo Cliente

class ExcelGenerator {
  static CellStyle _getHeaderStyle() {
    return CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      backgroundColorHex: ExcelColor.teal,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  static Future<void> _saveAndShare(Excel excel, String baseName, String title) async {
    final String fileName = "${baseName}_Klip_${DateFormat('dd-MM-yyyy_HHmm').format(DateTime.now())}.xlsx";
    final List<int>? fileBytes = excel.save();
    
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: title);
    }
  }

  // =================================================================
  //  REPORTES POR CATEGORÍAS
  // =================================================================

  static Future<void> generateMovementsReport(List<AppTransaction> transacciones) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Movimientos'];
    excel.delete('Sheet1');

    final headerStyle = _getHeaderStyle();
    final headers = ['Fecha', 'Tipo', 'Categoría', 'Descripción', 'Monto'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var t in transacciones) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.fecha)),
        TextCellValue(t.tipo.toString().split('.').last.toUpperCase()),
        TextCellValue(t.categoria ?? 'General'),
        TextCellValue(t.descripcion),
        DoubleCellValue(t.monto),
      ]);
    }

    await _saveAndShare(excel, 'Movimientos', 'Reporte de Movimientos Klip');
  }

  static Future<void> generateInventoryReport(List<Product> products) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Inventario'];
    excel.delete('Sheet1');

    final headerStyle = _getHeaderStyle();
    final headers = ['Código', 'Nombre', 'Categoría', 'Proveedor', 'Stock Actual', 'Stock Mínimo', 'Precio Venta'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var p in products) {
      sheet.appendRow([
        TextCellValue(p.codigoBarras ?? 'S/N'),
        TextCellValue(p.nombre),
        TextCellValue(p.categoria),
        TextCellValue(p.proveedor),
        IntCellValue(p.stock),
        IntCellValue(p.stockMinimo),
        DoubleCellValue(p.precio),
      ]);
    }

    await _saveAndShare(excel, 'Inventario', 'Reporte de Inventario Klip');
  }

  static Future<void> generateClientsReport(List<Cliente> clientes) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Clientes'];
    excel.delete('Sheet1');

    final headerStyle = _getHeaderStyle();
    final headers = ['ID', 'Cédula', 'Nombre', 'Teléfono', 'Email', 'Estado'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var c in clientes) {
      sheet.appendRow([
        TextCellValue(c.id.substring(0, 8)),
        TextCellValue(c.cedula),
        TextCellValue(c.nombre),
        TextCellValue(c.telefono ?? 'No registrado'),
        TextCellValue(c.email ?? 'No registrado'),
        TextCellValue(c.isActive ? 'Activo' : 'Inactivo'),
      ]);
    }

    await _saveAndShare(excel, 'Clientes', 'Reporte de Clientes Klip');
  }

  static Future<void> generateDebtorsReport(List<Cliente> clientes, Map<String, double> deudas) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Clientes_Fiados'];
    excel.delete('Sheet1');

    final headerStyle = _getHeaderStyle();
    final headers = ['ID', 'Cédula', 'Nombre', 'Teléfono', 'Deuda Total Pendiente'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var c in clientes) {
      final deuda = deudas[c.id] ?? 0.0;
      if (deuda > 0) {
        sheet.appendRow([
          TextCellValue(c.id.substring(0, 8)),
          TextCellValue(c.cedula),
          TextCellValue(c.nombre),
          TextCellValue(c.telefono ?? 'No registrado'),
          DoubleCellValue(deuda),
        ]);
      }
    }

    await _saveAndShare(excel, 'Cartera', 'Reporte de Cartera/Deudores Klip');
  }

  static Future<void> generateProvidersReport(List<Proveedor> proveedores) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Proveedores'];
    excel.delete('Sheet1');

    final headerStyle = _getHeaderStyle();
    final headers = ['Empresa', 'Contacto', 'Teléfono', 'Días Visita', 'Email', 'Notas'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var p in proveedores) {
      sheet.appendRow([
        TextCellValue(p.empresa),
        TextCellValue(p.contacto),
        TextCellValue(p.contacto),
        TextCellValue(p.diasVisita ?? ''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
    }

    await _saveAndShare(excel, 'Proveedores', 'Reporte de Proveedores Klip');
  }

  // =================================================================
  //  REPORTE GENERAL (Multilples Hojas)
  // =================================================================

  static Future<void> generateGeneralReport({
    required List<AppTransaction> transacciones,
    required List<Product> products,
    required List<Cliente> clientes,
    required Map<String, double> deudas,
    required List<Proveedor> proveedores,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final headerStyle = _getHeaderStyle();

    // 1. Resumen
    final Sheet sheetResumen = excel['Resumen General'];
    sheetResumen.appendRow([TextCellValue('Métrica'), TextCellValue('Valor')]);
    sheetResumen.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = headerStyle;
    sheetResumen.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).cellStyle = headerStyle;

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

    sheetResumen.appendRow([TextCellValue('Total Ingresos Histórico'), DoubleCellValue(ingresos)]);
    sheetResumen.appendRow([TextCellValue('Total Egresos Histórico'), DoubleCellValue(egresos)]);
    sheetResumen.appendRow([TextCellValue('Balance Histórico'), DoubleCellValue(ingresos - egresos)]);
    sheetResumen.appendRow([TextCellValue('Total Clientes Registrados'), IntCellValue(clientes.length)]);
    sheetResumen.appendRow([TextCellValue('Total Cartera (Por Cobrar)'), DoubleCellValue(totalCartera)]);
    sheetResumen.appendRow([TextCellValue('Valorización Inventario Aprox.'), DoubleCellValue(valorizacionInventario)]);
    sheetResumen.appendRow([TextCellValue('Total Proveedores'), IntCellValue(proveedores.length)]);

    await _saveAndShare(excel, 'Reporte_General', 'Reporte General del Negocio Klip');
  }
}
