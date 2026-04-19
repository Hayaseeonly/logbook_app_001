import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;

  VisionController() {
    // Mendaftarkan observer untuk memantau status aplikasi (Lifecycle) 
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      // Memilih Kamera Belakang (Index 0) 
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, 
        enableAudio: false, // Hanya butuh visual untuk deteksi jalan 
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
    }
    notifyListeners();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // Jika controller belum ada atau belum siap
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Lepaskan resource kamera saat aplikasi tidak terlihat
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      // Inisialisasi ulang saat pengguna kembali
      initCamera();
    }
  }

  @override
  void dispose() {
    // Menghapus observer dan memutus akses kamera 
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}