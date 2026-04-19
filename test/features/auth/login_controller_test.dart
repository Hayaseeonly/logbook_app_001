import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';

void main() {
  group('Modul 2 - LoginController Unit Test', () {
    late LoginController controller;

    setUp(() => controller = LoginController());

    test('1. Status awal isLocked harus false', () {
      expect(controller.isLocked, false);
    });

    test('2. Login Admin berhasil dengan password benar', () {
      bool result = controller.login("admin", "123");
      expect(result, true);
    });

    test('3. Login Mahasiswa berhasil dengan password benar', () {
      bool result = controller.login("mahasiswa", "polban");
      expect(result, true);
    });

    test('4. Login gagal jika password salah', () {
      bool result = controller.login("admin", "salah");
      expect(result, false);
    });

    test('5. Login gagal jika username tidak terdaftar', () {
      bool result = controller.login("hyouka", "123");
      expect(result, false);
    });

    test('6. Percobaan salah 1x tidak mengunci sistem', () {
      controller.login("admin", "salah");
      expect(controller.isLocked, false);
    });

    test('7. Percobaan salah 2x tidak mengunci sistem', () {
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      expect(controller.isLocked, false);
    });

    test('8. Percobaan salah 3x harus mengunci sistem (isLocked = true)', () {
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      expect(controller.isLocked, true);
    });

    test('9. Login selalu mengembalikan false jika status isLocked true', () {
      // Trigger lock
      for(int i=0; i<3; i++) controller.login("admin", "salah");
      
      // Coba login dengan data benar saat terkunci
      bool result = controller.login("admin", "123");
      expect(result, false);
    });
  });
}