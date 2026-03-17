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
    logsNotifier.value = _myBox.values.toList();
    
    try {
      final cloudData = await MongoService().getLogs(teamId);
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = cloudData;
      await LogHelper.writeLog("SYNC: Data sinkron dengan MongoDB Atlas", level: 2);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE: Menggunakan cache lokal (Hive)", level: 2);
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
    );

    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog("SUCCESS: Log tersimpan", source: _source);
    } catch (e) {
      await LogHelper.writeLog("WARNING: Offline mode - $e", level: 1);
    }
  }

  // LOG DENGAN VALIDASI KEAMANAN 

  Future<void> updateLog(int index, String title, String desc, String userId, String userRole, 
      {String category = "Pribadi", bool isPublic = false}) async {
    
    final oldLog = logsNotifier.value[index];
    
    // Cek apakah user adalah pemilik atau memiliki role yang diizinkan (misal: Ketua)
    final bool isOwner = AccessControlService.checkOwnership(oldLog.authorId, userId);
    if (!AccessControlService.canPerform(userRole, 'update', isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY: Upaya ubah ilegal oleh $userId", level: 1);
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
    );

    try {
      await _myBox.putAt(index, updatedLog);
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await MongoService().updateLog(updatedLog);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkron update - $e", level: 1);
    }
  }

  Future<void> removeLog(int index, String userRole, String userId) async {
    final target = logsNotifier.value[index];
    
    // Cek kepemilikan sebelum menghapus
    final bool isOwner = AccessControlService.checkOwnership(target.authorId, userId);
    if (!AccessControlService.canPerform(userRole, 'delete', isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY: Upaya hapus ilegal oleh $userId", level: 1);
      return;
    }

    try {
      await _myBox.deleteAt(index);
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      if (target.id != null) {
        await MongoService().deleteLog(target.id!);
      }
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal hapus - $e", level: 1);
    }
  }
}