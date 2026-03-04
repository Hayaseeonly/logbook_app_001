import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart'; 
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier("");
  final String _source = "log_controller.dart";

  // --- FITUR SEARCH ---
  List<LogModel> get filteredLogs {
    if (searchQueryNotifier.value.isEmpty) return logsNotifier.value;
    return logsNotifier.value.where((log) => 
      log.title.toLowerCase().contains(searchQueryNotifier.value.toLowerCase())
    ).toList();
  }

  void setSearchQuery(String query) {
    searchQueryNotifier.value = query;
  }

  // --- READ: LOAD DARI CLOUD ---
  Future<void> loadFromDisk() async {
    try {
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
      
      await LogHelper.writeLog("UI: Data berhasil dimuat dari Cloud", source: _source, level: 2);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal load data - $e", source: _source, level: 1);
      // --- PEMBARUAN: Rethrow error agar ditangkap FutureBuilder di LogView ---
      rethrow; 
    }
  }

  // --- CREATE: TAMBAH DATA KE CLOUD ---
  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(), 
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(), // Gunakan ISO8601 agar mudah di-parse intl
    );

    try {
      await MongoService().insertLog(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal tambah data - $e", source: _source, level: 1);
      rethrow;
    }
  }

  // --- UPDATE: EDIT DATA DI CLOUD ---
  Future<void> updateLog(int index, String title, String desc, String category) async {
    final oldLog = logsNotifier.value[index];
    
    final updatedLog = LogModel(
      id: oldLog.id, 
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
    );

    try {
      await MongoService().updateLog(updatedLog);
      
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal update data - $e", source: _source, level: 1);
      rethrow;
    }
  }

  // --- DELETE: HAPUS DATA DI CLOUD ---
  Future<void> removeLog(int index) async {
    final logToDelete = logsNotifier.value[index];
    
    if (logToDelete.id == null) return;

    try {
      await MongoService().deleteLog(logToDelete.id!);
      
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;
      
      await LogHelper.writeLog("UI: Berhasil menghapus '${logToDelete.title}'", source: _source, level: 2);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal hapus data - $e", source: _source, level: 1);
      rethrow;
    }
  }
}