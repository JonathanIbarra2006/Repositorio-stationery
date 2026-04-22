import 'package:flutter/material.dart';
import '../../data/services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _syncService = SyncService();
  bool _isUploading = false;
  bool _isDownloading = false;

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    try {
      await _syncService.uploadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización exitosa: Datos subidos a la nube'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      await _syncService.downloadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización exitosa: Datos descargados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.cloud_sync_rounded, size: 80, color: Color(0xFF00BFA5)),
          const SizedBox(height: 16),
          const Text(
            'Sincronización en la Nube',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mantén tus datos seguros sincronizándolos con Supabase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          
          // Upload Card
          _buildSyncCard(
            title: 'Subir Información',
            subtitle: 'Guarda tus datos locales en la nube.',
            icon: Icons.cloud_upload_rounded,
            isLoading: _isUploading,
            onTap: _isUploading || _isDownloading ? null : _handleUpload,
            color: const Color(0xFF00BFA5),
          ),
          
          const SizedBox(height: 20),
          
          // Download Card
          _buildSyncCard(
            title: 'Descargar Información',
            subtitle: 'Recupera tus datos desde la nube.',
            icon: Icons.cloud_download_rounded,
            isLoading: _isDownloading,
            onTap: _isUploading || _isDownloading ? null : _handleDownload,
            color: Colors.orangeAccent,
          ),
          
          const Spacer(),
          const Text(
            'Nota: La sincronización requiere conexión a internet.',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSyncCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
