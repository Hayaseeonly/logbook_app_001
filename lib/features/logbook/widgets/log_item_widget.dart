import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  // PERBAIKAN: Gunakan tanda tanya (?) agar parameter bisa bernilai null (Gatekeeper)
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color backgroundColor;

  const LogItemWidget({
    super.key,
    required this.log,
    this.onEdit,   // Hapus 'required' agar bisa menerima null
    this.onDelete, // Hapus 'required' agar bisa menerima null
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // LOGIKA PEMFORMATAN TANGGAL 
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
      child: ListTile(
        leading: Icon(
          log.id != null ? Icons.cloud_done : Icons.cloud_upload_outlined,
          color: log.id != null ? Colors.green : Colors.orange,
        ),
        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${log.category} • ${log.description}"),
            const SizedBox(height: 4),
            Text(
              "Dibuat: $formattedDate",
              style: TextStyle(
                fontSize: 11, 
                color: Colors.grey.shade700, 
                fontStyle: FontStyle.italic
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PERBAIKAN: Hanya tampilkan ikon jika onEdit tidak null (Sesuai Task 3)
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            
            // PERBAIKAN: Hanya tampilkan ikon jika onDelete tidak null (Sesuai Task 3)
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}