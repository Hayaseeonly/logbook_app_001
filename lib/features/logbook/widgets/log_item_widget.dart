import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color backgroundColor;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // LOGIKA PEMFORMATAN TANGGAL 
    String formattedDate;
    try {
      // Pastikan data tanggal valid sebelum di-parse
      DateTime dateTime = DateTime.parse(log.date);
      // Format: dd MMM yyyy 
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      // Fallback jika parsing gagal
      formattedDate = log.date;
    }

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.book),
        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${log.category} • ${log.description}"),
            const SizedBox(height: 4),
            Text(
              "Dibuat: $formattedDate", // Gunakan hasil format di sini
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
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
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