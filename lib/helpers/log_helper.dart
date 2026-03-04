import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(String message, {String source = "Unknown", int level = 2}) async {
    // 1. Ambil Konfigurasi dari .env
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String mutedSources = dotenv.env['LOG_MUTE'] ?? "";
    
    // 2. Fitur LOG_MUTE (Task 4.3): Cek apakah sumber ini dimatikan
    List<String> muteList = mutedSources.split(',').map((e) => e.trim()).toList();
    if (muteList.contains(source)) return;

    // 3. Verbosity Control (Task 4.2): Filter berdasarkan Level
    if (level > configLevel) return;

    try {
      DateTime now = DateTime.now();
      String timestamp = DateFormat('HH:mm:ss').format(now);
      String dateStamp = DateFormat('dd-MM-yyyy').format(now);
      String label = _getLabel(level);
      String color = _getColor(level);

      // --- LOG KE TERMINAL ---
      dev.log(message, name: source, time: now, level: level * 100);
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // --- LOG KE FILE FISIK (Task 4.1) ---
      // Membuat folder /logs jika belum ada
      final directory = Directory('logs');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Menulis/Menambah baris ke file dd-mm-yyyy.log
      final file = File('logs/$dateStamp.log');
      String logEntry = '[$timestamp][$label][$source] -> $message\n';
      
      await file.writeAsString(logEntry, mode: FileMode.append);
      
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1: return "ERROR";
      case 2: return "INFO";
      case 3: return "VERBOSE";
      default: return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1: return '\x1B[31m'; // Merah
      case 2: return '\x1B[32m'; // Hijau
      case 3: return '\x1B[34m'; // Biru
      default: return '\x1B[0m';
    }
  }
}