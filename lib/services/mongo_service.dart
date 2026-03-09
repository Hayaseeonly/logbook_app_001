import 'package:flutter/material.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../features/logbook/models/log_model.dart';
import '../helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;
  final String _source = "mongo_service.dart"; // Sekarang akan digunakan

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;
    
    try {
      final uri = dotenv.env['MONGODB_URI'];
      if (uri == null) throw Exception("MONGODB_URI tidak ditemukan");
      
      _db = await Db.create(uri);
      await _db!.open();
      // [FIX] Menggunakan _source agar tidak dianggap unused
      debugPrint("[$_source] MongoDB Atlas: Terhubung & Koleksi Siap");
    } catch (e) {
      debugPrint("[$_source] MongoDB Atlas Error: $e");
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      debugPrint("[$_source] MongoDB Atlas: Koneksi ditutup");
    }
  }

  Future<DbCollection> _getSafeCollection() async {
    await connect();
    return _db!.collection(dotenv.env['MONGODB_COLLECTION'] ?? 'logs');
  }

  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();
      final data = await collection.find(where.eq('teamId', teamId)).toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      // Menggunakan _source di LogHelper
      await LogHelper.writeLog("CLOUD ERROR: Fetch failed - $e", source: _source, level: 1);
      rethrow;
    }
  }

  Future<void> insertLog(LogModel log) async {
    final collection = await _getSafeCollection();
    await collection.insertOne(log.toMap());
  }

  Future<void> updateLog(LogModel log) async {
    if (log.id == null) return;
    final collection = await _getSafeCollection();
    await collection.replaceOne({'_id': ObjectId.fromHexString(log.id!)}, log.toMap());
  }

  Future<void> deleteLog(String id) async {
    final collection = await _getSafeCollection();
    await collection.deleteOne({'_id': ObjectId.fromHexString(id)});
  }
}