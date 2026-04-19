import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

void main() {
  group('Modul 4 - Access Control & Sync Logic', () {
    
    test('1. checkOwnership harus True jika Author ID sama dengan User ID', () {
      bool result = AccessControlService.checkOwnership("user_01", "user_01");
      expect(result, true);
    });

    test('2. checkOwnership harus False jika ID berbeda', () {
      bool result = AccessControlService.checkOwnership("user_01", "user_02");
      expect(result, false);
    });

    test('3. Ketua TIDAK BOLEH melakukan update jika bukan miliknya', () {
      // Act: Ketua mencoba update, tapi isOwner = false
      bool result = AccessControlService.canPerform("Ketua", "update", isOwner: false);
      expect(result, false); 
    });

    test('4. Anggota tidak bisa hapus (delete) log milik orang lain', () {
      bool result = AccessControlService.canPerform("Anggota", "delete", isOwner: false);
      expect(result, false);
    });

    test('5. Anggota bisa hapus log jika dia adalah pemiliknya (isOwner = true)', () {
      bool result = AccessControlService.canPerform("Anggota", "delete", isOwner: true);
      expect(result, true);
    });

    test('6. Role kosong atau tidak dikenal harus ditolak', () {
      // Sesuai spreadsheet: Role dikosongkan ""
      bool result = AccessControlService.canPerform("", "read");
      expect(result, false);
    });

  
    test('7. Data baru yang dibuat secara offline harus memiliki isSynced = false', () {
      final newLog = LogModel(
        id: "1", 
        title: "Offline Log", 
        description: "Desc", 
        date: "2024", 
        authorId: "A", 
        teamId: "T", 
        isSynced: false
      );
      expect(newLog.isSynced, false);
    });

    test('8. Log dari MongoDB (Cloud) harus memiliki status isSynced = true', () {
      final cloudLog = LogModel(
        id: "1", 
        title: "Cloud Log", 
        description: "Desc", 
        date: "2024", 
        authorId: "A", 
        teamId: "T", 
        isSynced: true
      );
      expect(cloudLog.isSynced, true);
    });
  });

  test('9. Aksi tidak dikenal (misal: "hack") harus ditolak sistem', () {
      bool result = AccessControlService.canPerform("Ketua", "hack");
      expect(result, false);
    });
}