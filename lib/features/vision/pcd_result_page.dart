import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../services/pcd_service.dart';

class PcdResultPage extends StatefulWidget {
  final String imagePath;
  final String filterName;

  const PcdResultPage({
    super.key, 
    required this.imagePath, 
    required this.filterName
  });

  @override
  State<PcdResultPage> createState() => _PcdResultPageState();
}

class _PcdResultPageState extends State<PcdResultPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _applyPcdFilter();
  }

  Future<void> _applyPcdFilter() async {
    // Gunakan compute() agar pemrosesan citra tidak memblokir main thread
    final result = await compute(_processImage, {
      'path': widget.imagePath,
      'filter': widget.filterName,
    });

    if (mounted) {
      setState(() {
        _imageBytes = result;
        _isLoading = false;
      });
    }
  }

  // Fungsi statis untuk dijalankan di Isolate
  static Uint8List _processImage(Map<String, dynamic> params) {
    final String path = params['path'];
    final String filter = params['filter'];
    
    final bytes = File(path).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) return bytes;

    img.Image filtered;
    switch (filter) {
      case "Grayscale": filtered = PcdService.applyGrayscale(image); break;
      case "Biner": filtered = PcdService.applyBiner(image); break;
      case "Inverse": filtered = PcdService.applyInverse(image); break;
      case "Low pass": filtered = PcdService.applyLowPass(image); break;
      case "High pass": filtered = PcdService.applyHighPass(image); break;
      case "Band pass": filtered = PcdService.applyBandPass(image); break;
      case "Mean": filtered = PcdService.applyMean(image); break;
      case "Gaussian": filtered = PcdService.applyGaussian(image); break;
      case "Histogram equalization": filtered = PcdService.applyHistogramEqualization(image); break;
      case "Adaptive histogram equalization": filtered = PcdService.applyAdaptiveHistogram(image); break;
      case "Histogram specification": filtered = PcdService.applyHistogramSpecification(image); break;
      default: filtered = image;
    }

    return Uint8List.fromList(img.encodeJpg(filtered));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PCD Result: ${widget.filterName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur simpan akan segera hadir!")),
              );
            },
          )
        ],
      ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator() 
            : InteractiveViewer(
                child: Image.memory(_imageBytes!),
              ),
      ),
    );
  }
}