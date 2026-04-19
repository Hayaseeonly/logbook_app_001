import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import '../../services/pcd_service.dart'; // Pastikan file ini sudah dibuat

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  
  // Task 4: Variabel Simulasi Deteksi Dinamis (Mock Detection) [cite: 354, 356]
  Rect? _mockBox;
  Timer? _timer;

  // Homework: Kontrol Hardware & UI Layering 
  bool _isFlashOn = false;
  bool _isOverlayVisible = true;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _startMockDetection(); // Implementasi Simulasi [cite: 356, 360]
  }

  // Task 4: Logika memindahkan kotak deteksi secara acak setiap 3 detik [cite: 356]
  void _startMockDetection() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Nilai normalisasi 0.0 - 1.0 untuk akurasi lintas perangkat [cite: 110, 319-320]
          _mockBox = Rect.fromLTWH(
            Random().nextDouble() * 0.6,
            Random().nextDouble() * 0.6,
            0.3, // Lebar 30% dari layar [cite: 357]
            0.2, // Tinggi 20% dari layar [cite: 357]
          );
        });
      }
    });
  }

  // Homework: Mengendalikan Fitur Spesifik Hardware (Flashlight) [cite: 370, 372]
  Future<void> _toggleFlash() async {
    if (_visionController.controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _visionController.controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  // Fitur "Jeprek": Menangkap Citra untuk Pemrosesan PCD [cite: 149-151]
  Future<void> _captureAndFilter() async {
    try {
      final image = await _visionController.controller!.takePicture();
      if (!mounted) return;

      _showPcdMenu(image.path);
    } catch (e) {
      debugPrint("Error capture: $e");
    }
  }

  // Menu Pilihan Filter PCD Lengkap (Point, Spatial, Edge, Analysis)
  void _showPcdMenu(String path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("PCD - Road Damage Enhancement", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            // 1. Point Processing (Manipulasi Piksel Mandiri)
            _buildFilterGroup("1. Point Processing", 
              ["Brightness", "Contrast", "Grayscale", "Negative", "Thresholding"]),
            // 2. Spatial Filtering (Konvolusi & Kernel)
            _buildFilterGroup("2. Spatial Filtering", 
              ["Mean Filter", "Gaussian Blur", "Median Filter", "Laplacian", "Unsharp Masking"]),
            // 3. Edge Detection (Indra Pendeteksi Infrastruktur)
            _buildFilterGroup("3. Edge Detection", 
              ["Sobel Operator", "Prewitt Operator", "Roberts Operator", "Canny Edge Detection"]),
            // 4. Analisis Histogram
            _buildFilterGroup("4. Analisis Citra", 
              ["Histogram Analysis", "Histogram Equalization"]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterGroup(String title, List<String> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
        ...filters.map((filterName) => ListTile(
          leading: const Icon(Icons.filter_vintage_outlined, size: 20),
          title: Text(filterName),
          onTap: () {
            Navigator.pop(context);
            // Integrasi ke PcdResultPage untuk melihat hasil olahan citra
          },
        )),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visionController.dispose(); // Lifecycle Safety: Melepaskan hardware [cite: 85-86, 230-232, 358]
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Hapus extendBehindAppBar sementara jika Flutter kamu versi lama, 
      // atau pastikan letaknya tepat di bawah backgroundColor/appBar.
      extendBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        backgroundColor: Colors.transparent, // Agar preview kamera terlihat di balik AppBar [cite: 66]
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(_isOverlayVisible ? Icons.layers : Icons.layers_clear),
            onPressed: () => setState(() => _isOverlayVisible = !_isOverlayVisible),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke Sensor...", style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }
          return _buildVisionStack();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _captureAndFilter,
        backgroundColor: Colors.white.withOpacity(0.3),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
      ),
    );
  }
}