import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'package:logbook_app_001/services/pcd_service.dart'

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
            _buildFilterGroup("1. Point Processing", ["Brightness", "Contrast", "Grayscale", "Negative", "Thresholding"]),
            _buildFilterGroup("2. Spatial Filtering", ["Mean Filter", "Gaussian Blur", "Median Filter", "Laplacian", "Unsharp Masking"]),
            _buildFilterGroup("3. Edge Detection", ["Sobel", "Prewitt", "Roberts", "Canny"]),
            _buildFilterGroup("4. Analisis Citra", ["Histogram Analysis", "Histogram Equalization"]),
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
        ...filters.map((f) => ListTile(
          leading: const Icon(Icons.filter_vintage_outlined, size: 20),
          title: Text(f),
          onTap: () => Navigator.pop(context),
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
      extendBehindAppBar: true, // Parameter Scaffold
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
          return _buildVisionStack(); // Metode dipanggil di sini
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _captureAndFilter,
        backgroundColor: Colors.white.withValues(alpha: 0.3), // Pengganti withOpacity
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
      ),
    );
  }

  // FIXED: Definisi metode _buildVisionStack yang sebelumnya hilang
  Widget _buildVisionStack() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Transform.scale(
            scale: 1 / (_visionController.controller!.value.aspectRatio * deviceRatio),
            child: AspectRatio(
              aspectRatio: _visionController.controller!.value.aspectRatio,
              child: CameraPreview(_visionController.controller!),
            ),
          ),
        ),
        if (_isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                mockBox: _mockBox, // Menggunakan mockBox agar sinkron
                label: "D40 POTHOLE - 92%",
              ),
            ),
          ),
      ],
    );
  }
}