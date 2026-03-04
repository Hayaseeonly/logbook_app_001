import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan ini untuk Lokalisasi
import 'package:logbook_app_001/services/mongo_service.dart'; 
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

Future<void> main() async {
  // 1. Wajib dipanggil sebelum inisialisasi asinkron lainnya
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load konfigurasi keamanan dari file .env 
  await dotenv.load(fileName: ".env");

  // 3. WAJIB: Inisialisasi data tanggal untuk format Indonesia (PR Task 3)
  // Ini yang bikin format "25 Jan 2026" kamu nggak error
  await initializeDateFormatting('id_ID', null);

  // 4. Inisialisasi koneksi MongoDB saat start-up
  try {
    await MongoService().connect();
  } catch (e) {
    // Log error tanpa menghentikan aplikasi (UI akan handle via Connection Guard)
    debugPrint("Koneksi awal gagal: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook Cloud', 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}