import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color backgroundColor;

  const LogItemWidget({
    super.key,
    required this.log,
    this.onEdit,
    this.onDelete,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate;
    try {
      DateTime dateTime = DateTime.parse(log.date);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      formattedDate = log.date;
    }

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS JUDUL UTAMA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    log.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                // INDIKATOR SINKRONISASI (AWAN)
                Icon(
                  log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 20,
                  color: log.isSynced ? Colors.green : Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // BARIS INFORMASI: Pembuat, Kategori, Status
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildInfoTag(Icons.person_outline, "${log.authorName} (${log.authorRole})", Colors.blueGrey),
                _buildInfoTag(Icons.category_outlined, log.category, Colors.teal),
                _buildInfoTag(
                  log.isPublic ? Icons.public : Icons.lock_outline,
                  log.isPublic ? "Publik" : "Privat",
                  log.isPublic ? Colors.green : Colors.red,
                ),
                // Status Sinkronisasi Teks
                _buildInfoTag(
                  log.isSynced ? Icons.check_circle_outline : Icons.sync_problem,
                  log.isSynced ? "Cloud Atlas" : "Lokal",
                  log.isSynced ? Colors.green : Colors.red,
                ),
              ],
            ),
            
            const Divider(height: 24),

            // AREA PRATINJAU DESKRIPSI (Merender Markdown)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: MarkdownBody(
                data: log.description,
                selectable: false,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(color: Colors.grey.shade900, fontSize: 14),
                  h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  listBullet: TextStyle(color: Colors.grey.shade900),
                ),
              ),
            ),
            
            if (log.description.length > 200)
              Text("...", style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 10),
            
            // Tanggal & Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dibuat: $formattedDate",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                // Tombol Aksi (Edit/Hapus)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}