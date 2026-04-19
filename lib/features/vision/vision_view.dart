import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'pcd_result_page.dart'; // Import halaman hasil baru
import 'package:logbook_app_001/services/pcd_service.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  Rect? _mockBox;
  Timer? _timer;
  bool _isFlashOn = false;
  bool _isOverlayVisible = true;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _startMockDetection();
  }

  void _startMockDetection() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _mockBox = Rect.fromLTWH(
            Random().nextDouble() * 0.6,
            Random().nextDouble() * 0.6,
            0.3,
            0.2,
          );
        });
      }
    });
  }

  Future<void> _toggleFlash() async {
    if (_visionController.controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _visionController.controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _captureAndFilter() async {
    try {
      final image = await _visionController.controller!.takePicture();
      if (!mounted) return;
      // Kirim path gambar ke menu
      _showPcdMenu(image.path);
    } catch (e) {
      debugPrint("Error capture: $e");
    }
  }

  void _showPcdMenu(String path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("SMART-PATROL: 11 PCD FILTERS", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            // Median sudah dihapus dari daftar
            _buildFilterGroup("Point Processing", ["Grayscale", "Biner", "Inverse"], path),
            _buildFilterGroup("Frequency Domain", ["Low pass", "High pass", "Band pass"], path),
            _buildFilterGroup("Spatial Filtering", ["Mean", "Gaussian"], path),
            _buildFilterGroup("Histogram Analysis", ["Histogram equalization", "Adaptive histogram equalization", "Histogram specification"], path),
          ],
        ),
      ),
    );
  }

  // Tambahkan parameter imagePath di sini
  Widget _buildFilterGroup(String title, List<String> filters, String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
        ...filters.map((f) => ListTile(
          title: Text(f),
          leading: const Icon(Icons.auto_fix_high),
          onTap: () {
            Navigator.pop(context); // Tutup menu
            // Navigasi ke halaman hasil
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PcdResultPage(
                  imagePath: imagePath,
                  filterName: f,
                ),
              ),
            );
          },
        )),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        backgroundColor: Colors.transparent,
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
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          return _buildVisionStack();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _captureAndFilter,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildVisionStack() {
    // 1. Ambil ukuran layar perangkat
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Kamera dengan koreksi Transform.scale
        Center(
          child: Transform.scale(
            // RUMUS: Skala = 1 / (Rasio Kamera * Rasio Perangkat)
            // Ini memastikan preview kamera menutupi layar tanpa distorsi (cropping)
            scale: 1 / (_visionController.controller!.value.aspectRatio * deviceRatio),
            child: AspectRatio(
              aspectRatio: _visionController.controller!.value.aspectRatio,
              child: CameraPreview(_visionController.controller!),
            ),
          ),
        ),

        // LAYER 2: Digital Overlay (Hanya muncul jika _isOverlayVisible true)
        if (_isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                mockBox: _mockBox, 
                label: "D40 POTHOLE - 92%", 
              ),
            ),
          ),
      ],
    );
  }
}