import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() {
  // Gunakan ID heksadesimal 24 karakter yang valid
  const String validId = "507f191e810c19729de860ea";

  group('Modul 3 - Log Modeling & Search Test', () {
    late LogController controller;

    setUpAll(() async {
      // Inisialisasi Hive untuk testing (menggunakan folder sementara)
      final path = Directory.current.path;
      Hive.init(path);
      
      // Register adapter jika kamu menggunakan TypeAdapter (biasanya dihasilkan log_model.g.dart)
      // Jika belum ada adapter, abaikan baris ini atau pastikan LogModel terdaftar
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LogModelAdapter());
      }
    });

    setUp(() async {
      // Pastikan Box terbuka sebelum membuat controller
      if (!Hive.isBoxOpen('offline_logs')) {
        await Hive.openBox<LogModel>('offline_logs');
      }
      controller = LogController();
    });

    tearDown(() async {
      await Hive.close();
    });

    test('1. LogModel toMap harus mengonversi data dengan benar', () {
      final log = LogModel(
        id: validId, // Gunakan ID 24 karakter
        title: "Test", 
        description: "Desc", 
        date: "2024-01-01", 
        authorId: "user1", 
        teamId: "team1", 
        isSynced: false
      );
      final map = log.toMap();
      expect(map['title'], "Test");
      expect(map['_id'], isA<ObjectId>());
    });

    test('2. LogModel copyWith harus bisa mengubah status isSynced', () {
      final log = LogModel(
        id: validId, 
        title: "T", 
        description: "D", 
        date: "2024", 
        authorId: "A", 
        teamId: "T", 
        isSynced: false
      );
      final updated = log.copyWith(isSynced: true);
      expect(updated.isSynced, true);
    });

    test('3. SearchQuery kosong harus menampilkan semua log', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "A", description: "D", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("");
      expect(controller.filteredLogs.length, 1);
    });

    test('4. Pencarian berdasarkan judul (Normal Match)', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "Rapat", description: "Pembahasan", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("Rapat");
      expect(controller.filteredLogs.length, 1);
    });

    test('5. Pencarian harus Case Insensitive', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "LAPORAN", description: "D", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("laporan");
      expect(controller.filteredLogs.length, 1);
    });

    test('6. Pencarian pada bagian deskripsi', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "A", description: "Bekerja di Lab", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("Lab");
      expect(controller.filteredLogs.length, 1);
    });

    test('7. filteredLogs tidak boleh menampilkan data jika keyword tidak ada', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "Tugas", description: "D", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("Main Game");
      expect(controller.filteredLogs.length, 0);
    });

    test('8. Update logsNotifier harus langsung memengaruhi filteredLogs', () {
      controller.setSearchQuery("Urgent");
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "Urgent Task", description: "D", date: "now", authorId: "1", teamId: "1")
      ];
      expect(controller.filteredLogs.length, 1);
    });

    test('9. Pencarian parsial (mencari kata di tengah kalimat)', () {
      controller.logsNotifier.value = [
        LogModel(id: validId, title: "Monitoring Jaringan", description: "D", date: "now", authorId: "1", teamId: "1")
      ];
      controller.setSearchQuery("ring");
      expect(controller.filteredLogs.length, 1);
    });
  });
}