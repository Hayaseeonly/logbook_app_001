import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../../services/mongo_service.dart';
import '../../services/access_control_service.dart';
import '../../helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier("");
  final String _source = "log_controller.dart";
  
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

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

  Future<void> loadLogs(String teamId) async {
    // Tampilkan data lokal saat ini
    logsNotifier.value = _myBox.values.toList();
    
    try {
      // 1. Ambil data terbaru dari Cloud
      final cloudData = await MongoService().getLogs(teamId);
      
      // 2. Buat daftar ID yang sudah ada di Cloud
      final cloudIds = cloudData.map((l) => l.id).toSet();

      // 3. Filter data lokal: HANYA ambil yang belum sinkron DAN belum ada di Cloud
      final pendingLogs = _myBox.values.where((l) => 
        !l.isSynced && !cloudIds.contains(l.id)
      ).toList();
      
      // 4. Bersihkan Hive dan susun ulang
      await _myBox.clear();
      await _myBox.addAll(cloudData);   // Data ijo (isSynced otomatis true dari LogModel.fromMap)
      await _myBox.addAll(pendingLogs); // Data merah yang beneran belum masuk Atlas
      
      // 5. Update UI
      logsNotifier.value = _myBox.values.toList();
      await LogHelper.writeLog("SYNC SUCCESS: Data sinkron dengan MongoDB Atlas", level: 2);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE MODE: Menggunakan cache lokal", level: 1);
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId, {
    String category = 'Pribadi',
    bool isPublic = false,
    required Map<String, dynamic> user, 
  }) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      category: category,
      isPublic: isPublic,
      authorName: user['username'] ?? 'User',
      authorRole: user['role'] ?? 'Anggota',
      isSynced: false,
    );

    // Simpan ke Hive
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLog(newLog);
      
      // Jika sukses, cari item tadi di Hive dan tandai Ijo
      // Cari berdasarkan ID karena index add() bisa bergeser saat loadLogs berjalan
      final key = _myBox.keys.firstWhere((k) => _myBox.get(k)?.id == newLog.id);
      final syncedLog = newLog.copyWith(isSynced: true);
      await _myBox.put(key, syncedLog);
      
      _updateLocalListStatus(newLog.id!, syncedLog);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE: Log disimpan lokal", level: 1);
    }
  }

  Future<void> syncPendingLogs() async {
    final keys = _myBox.keys.toList();
    
    for (var key in keys) {
      final log = _myBox.get(key);
      
      if (log != null && !log.isSynced) {
        try {
          // Coba kirim ke Cloud
          await MongoService().insertLog(log);
          
          // Jika sukses, update data di Hive menggunakan Key aslinya
          final syncedLog = log.copyWith(isSynced: true);
          await _myBox.put(key, syncedLog);
          
          _updateLocalListStatus(log.id!, syncedLog);
          debugPrint("Synced successfully: ${log.title}");
        } catch (e) {
          debugPrint("Sync failed for ${log.title}: $e");
        }
      }
    }
  }

  void _updateLocalListStatus(String id, LogModel updatedLog) {
    final currentList = List<LogModel>.from(logsNotifier.value);
    final itemIndex = currentList.indexWhere((l) => l.id == id);
    if (itemIndex != -1) {
      currentList[itemIndex] = updatedLog;
      logsNotifier.value = currentList;
    }
  }

  Future<void> updateLog(int index, String title, String desc, String userId, String userRole, 
      {String category = "Pribadi", bool isPublic = false}) async {
    
    final oldLog = logsNotifier.value[index];
    final bool isOwner = AccessControlService.checkOwnership(oldLog.authorId, userId);
    
    if (!AccessControlService.canPerform(userRole, 'update', isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY: Unauthorized update", level: 1);
      return;
    }

    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      category: category,
      isPublic: isPublic,
      authorName: oldLog.authorName,
      authorRole: oldLog.authorRole,
      isSynced: false, 
    );

    try {
      // Cari key aslinya di Hive
      final key = _myBox.keys.firstWhere((k) => _myBox.get(k)?.id == oldLog.id);
      await _myBox.put(key, updatedLog);
      
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await MongoService().updateLog(updatedLog);
      
      final syncedLog = updatedLog.copyWith(isSynced: true);
      await _myBox.put(key, syncedLog);
      _updateLocalListStatus(updatedLog.id!, syncedLog);
      
    } catch (e) {
      await LogHelper.writeLog("ERROR: Cloud update failed", level: 1);
    }
  }

  Future<void> removeLog(int index, String userRole, String userId) async {
    final target = logsNotifier.value[index];
    final bool isOwner = AccessControlService.checkOwnership(target.authorId, userId);
    
    if (!AccessControlService.canPerform(userRole, 'delete', isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY: Unauthorized delete", level: 1);
      return;
    }

    try {
      final key = _myBox.keys.firstWhere((k) => _myBox.get(k)?.id == target.id);
      await _myBox.delete(key);
      
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      if (target.id != null) {
        await MongoService().deleteLog(target.id!);
      }
    } catch (e) {
      await LogHelper.writeLog("ERROR: Cloud delete failed", level: 1);
    }
  }
}