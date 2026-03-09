import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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