import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/mongo_service.dart';
import '../../services/access_control_service.dart';
import '../../helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier("");
  final String _source = "log_controller.dart";
  
  // Mengambil box Hive yang sudah dibuka di main.dart
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  // FITUR SEARCH (In-Memory)
  List<LogModel> get filteredLogs {
    if (searchQueryNotifier.value.isEmpty) return logsNotifier.value;
    return logsNotifier.value.where((log) => 
      log.title.toLowerCase().contains(searchQueryNotifier.value.toLowerCase()) ||
      log.description.toLowerCase().contains(searchQueryNotifier.value.toLowerCase())
    ).toList();
  }

  void setSearchQuery(String query) {
    searchQueryNotifier.value = query;
  }

  // LOAD DATA (Strategi Offline-First)
  Future<void> loadLogs(String teamId) async {
    // Aksi 1: Ambil data dari Hive 
    logsNotifier.value = _myBox.values.toList();
    
    // Sinkronisasi dari Cloud di latar belakang
    try {
      final cloudData = await MongoService().getLogs(teamId);
      
      // Update Hive dengan data terbaru dari Cloud agar sinkron
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      
      // Update tampilan UI dengan data Cloud
      logsNotifier.value = cloudData;
      
      await LogHelper.writeLog("SYNC: Data sinkron dengan MongoDB Atlas", level: 2);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE: Menggunakan cache lokal (Hive)", level: 2);
    }
  }

  // ADD DATA (Instant Local + Background Cloud)
  Future<void> addLog(String title, String desc, String authorId, String teamId, 
      {String category = "Pribadi", bool isPublic = false}) async {
    
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic,
    );

    // ACTION 1: Simpan ke Hive 
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // ACTION 2: Kirim ke MongoDB Atlas
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog("SUCCESS: Data tersinkron ke Cloud", source: _source);
    } catch (e) {
      await LogHelper.writeLog("WARNING: Disimpan lokal, akan sinkron saat online", level: 1);
    }
  }

  // UPDATE DATA 
  Future<void> updateLog(int index, String title, String desc, 
      {String category = "Pribadi", bool isPublic = false}) async {
    
    final oldLog = logsNotifier.value[index];
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      isPublic: isPublic,
    );

    try {
      // Update Lokal
      await _myBox.putAt(index, updatedLog);
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      // Update Cloud
      await MongoService().updateLog(updatedLog);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkron update - $e", level: 1);
    }
  }

  // DELETE DATA 
  Future<void> removeLog(int index, String userRole, String userId) async {
    final target = logsNotifier.value[index];
    
    // VALIDASI RBAC: Cek izin hapus
    if (!AccessControlService.canPerform(userRole, 'delete', isOwner: target.authorId == userId)) {
      await LogHelper.writeLog("SECURITY: Upaya hapus ilegal oleh $userId", level: 1);
      return;
    }

    try {
      // Hapus Lokal
      await _myBox.deleteAt(index);
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      // Hapus Cloud
      if (target.id != null) {
        await MongoService().deleteLog(target.id!);
      }
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal hapus - $e", level: 1);
    }
  }
}