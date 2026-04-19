import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart'; // 
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

// Variabel global untuk menyimpan daftar kamera 
List<CameraDescription> cameras = []; 

Future<void> main() async {
  // Pastikan inisialisasi binding sudah dipanggil 
  WidgetsFlutterBinding.ensureInitialized();

  // Ambil daftar kamera yang tersedia di perangkat 
  try {
    cameras = await availableCameras(); // 
  } on CameraException catch (e) {
    debugPrint('Error: ${e.code}\nError Message: ${e.description}'); // 
  }

  await dotenv.load(fileName: ".env");

  // Setup Hive
  await Hive.initFlutter(); 
  Hive.registerAdapter(LogModelAdapter()); 
  await Hive.openBox<LogModel>('offline_logs'); 

  await initializeDateFormatting('id_ID', null);

  try {
    await MongoService().connect();
  } catch (e) {
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