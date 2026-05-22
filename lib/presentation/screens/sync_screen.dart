import 'package:flutter/material.dart';
import '../../data/services/sync_service.dart';
import '../../core/theme/app_theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {
  final _syncService = SyncService();

  bool _isUploading = false;
  bool _isDownloading = false;

  SyncResult? _lastUploadResult;
  SyncResult? _lastDownloadResult;
  String? _errorMessage;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<bool> _confirmAction(String title, String content, String confirmText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    bool isObscure = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: AppColors.electricBlue, size: 28),
                SizedBox(width: 10),
                Text('Autorización', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para proteger tus datos y sincronizar las eliminaciones con Supabase, ingresa tu contraseña de inicio de sesión.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setStateDialog(() => isObscure = !isObscure);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final pass = controller.text.trim();
                  if (pass.isNotEmpty) Navigator.pop(context, pass);
                },
                child: const Text('Autorizar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
    return result;
  }

  Future<void> _handleUpload() async {
    final password = await _promptForPassword();
    if (password == null) return;

    setState(() {
      _isUploading = true;
      _lastUploadResult = null;
      _errorMessage = null;
    });
    try {
      final result = await _syncService.uploadData(password: password);
      if (mounted) {
        setState(() => _lastUploadResult = result);
        _showResultSnackBar(
          success: result.warnings.isEmpty,
          message: result.warnings.isEmpty
              ? '✓ ${result.totalRecords} registros subidos correctamente'
              : 'Subida parcial: ${result.totalRecords} registros (${result.warnings.length} advertencias)',
        );
      }
    } on SyncException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDownload() async {
    final confirm = await _confirmAction(
      '¿Descargar Cambios?',
      'Se descargarán los datos de Supabase. Los datos locales existentes se combinarán inteligentemente sin sobreescribir tus ediciones locales. ¿Continuar?',
      'Descargar Datos',
    );
    if (!confirm) return;

    setState(() {
      _isDownloading = true;
      _lastDownloadResult = null;
      _errorMessage = null;
    });
    try {
      final result = await _syncService.downloadData();
      if (mounted) {
        setState(() => _lastDownloadResult = result);
        _showResultSnackBar(
          success: result.warnings.isEmpty,
          message: result.warnings.isEmpty
              ? '✓ ${result.totalRecords} registros descargados correctamente'
              : 'Descarga parcial: ${result.totalRecords} registros (${result.warnings.length} advertencias)',
        );
      }
    } on SyncException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showResultSnackBar({required bool success, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.cloud_done_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBusy = _isUploading || _isDownloading;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Ícono animado ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricBlue.withValues(
                    alpha: 0.06 + _pulseController.value * 0.06,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withValues(
                        alpha: 0.10 + _pulseController.value * 0.08,
                      ),
                      blurRadius: 30 + _pulseController.value * 10,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isBusy
                      ? Icons.sync_rounded
                      : Icons.cloud_sync_rounded,
                  size: 56,
                  color: AppColors.electricBlue,
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'Sincronización en la Nube',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mantén tus datos seguros respaldándolos en Supabase',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),

          // ── Error global ───────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!, onDismiss: () {
              setState(() => _errorMessage = null);
            }),
            const SizedBox(height: 16),
          ],

          // ── Tarjeta: Subir ─────────────────────────────────────────────────
          _SyncCard(
            title: 'Subir Información',
            subtitle: 'Guarda tus datos locales en Supabase',
            icon: Icons.cloud_upload_rounded,
            color: AppColors.electricBlue,
            isLoading: _isUploading,
            isDisabled: isBusy,
            result: _lastUploadResult,
            onTap: _handleUpload,
          ),
          const SizedBox(height: 16),

          // ── Tarjeta: Descargar ─────────────────────────────────────────────
          _SyncCard(
            title: 'Descargar Información',
            subtitle: 'Recupera tus datos desde Supabase',
            icon: Icons.cloud_download_rounded,
            color: const Color(0xFFF59E0B),
            isLoading: _isDownloading,
            isDisabled: isBusy,
            result: _lastDownloadResult,
            onTap: _handleDownload,
          ),
          const SizedBox(height: 32),

          // ── Nota informativa ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.electricBlue.withValues(alpha: 0.15),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.electricBlue,
                  size: 18,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'La sincronización requiere conexión a internet y cuenta activa en Supabase.',
                    style: TextStyle(fontSize: 12, color: AppColors.electricBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tarjeta de sincronización
// ──────────────────────────────────────────────────────────────────────────────

class _SyncCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final SyncResult? result;
  final VoidCallback onTap;

  const _SyncCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasWarnings = result != null && result!.warnings.isNotEmpty;

    return AnimatedOpacity(
      opacity: isDisabled && !isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: result != null
                ? (hasWarnings ? AppColors.warning : AppColors.success).withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícono
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: color,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoading
                                ? 'Procesando...'
                                : subtitle,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indicador de resultado
                    if (result != null && !isLoading)
                      Icon(
                        hasWarnings
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: hasWarnings ? AppColors.warning : AppColors.success,
                        size: 22,
                      )
                    else if (!isLoading)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                  ],
                ),

                // ── Resumen de resultado ──────────────────────────────────
                if (result != null && !isLoading) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: result!.tablesCounts.entries.map((e) {
                      return _TableChip(table: e.key, count: e.value);
                    }).toList(),
                  ),
                  if (hasWarnings) ...[
                    const SizedBox(height: 12),
                    ...result!.warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                w,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip que muestra el nombre de tabla y cuántos registros se sincronizaron
class _TableChip extends StatelessWidget {
  final String table;
  final int count;

  const _TableChip({required this.table, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '$table: $count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.electricBlue,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Banner de error
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}


