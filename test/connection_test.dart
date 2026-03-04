import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

void main() {
  // Menyiapkan environment sebelum tes dijalankan
  setUpAll(() async {
    // Pastikan file .env ada di root project
    await dotenv.load(fileName: ".env");
  });

  test('Verifikasi Koneksi MongoDB Atlas', () async {
    final mongoService = MongoService();
    
    await LogHelper.writeLog("--- START SMOKE TESTING ---", source: "connection_test.dart");

    try {
      // Mencoba koneksi
      await mongoService.connect();
      
      // Jika sampai sini tanpa error, berarti koneksi sukses
      expect(mongoService, isNotNull);
      
      await LogHelper.writeLog("SUCCESS: Terhubung ke MongoDB Atlas", source: "connection_test.dart", level: 2);
    } catch (e) {
      fail("Koneksi gagal: $e");
    } finally {
      await mongoService.close();
    }
  });
}