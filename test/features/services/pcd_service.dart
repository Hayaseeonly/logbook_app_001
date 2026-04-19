import 'package:image/image.dart' as img;

class PcdService {
  // === 1. POINT PROCESSING ===
  static img.Image applyGrayscale(img.Image src) => img.grayscale(src);
  static img.Image applyBrightness(img.Image src, int v) => img.adjustColor(src, brightness: v / 100);
  static img.Image applyContrast(img.Image src, double v) => img.contrast(src, contrast: v);
  static img.Image applyNegative(img.Image src) => img.invert(src);
  static img.Image applyThreshold(img.Image src, int t) => img.luminanceThreshold(src, threshold: t / 255);

  // === 2. SPATIAL FILTERING (KERNEL) ===
  static img.Image applyMean(img.Image src) => img.convolution(src, filter: [1, 1, 1, 1, 1, 1, 1, 1, 1], div: 9);
  static img.Image applyGaussian(img.Image src) => img.gaussianBlur(src, radius: 3);
  static img.Image applyMedian(img.Image src) => img.medianFilter(src, radius: 2);
  static img.Image applyLaplacian(img.Image src) => img.convolution(src, filter: [0, -1, 0, -1, 4, -1, 0, -1, 0]);
  static img.Image applyUnsharp(img.Image src) {
    final blurred = img.gaussianBlur(src, radius: 2);
    return img.compositeImage(src, blurred, blend: img.BlendMode.difference);
  }

  // === 3. EDGE DETECTION ===
  static img.Image applySobel(img.Image src) => img.sobel(src);
  static img.Image applyCanny(img.Image src) => img.canny(src);

  // === 4. ANALISIS HISTOGRAM ===
  static List<int> getHistogram(img.Image src) {
    List<int> histo = List.filled(256, 0);
    for (var pixel in src) {
      histo[img.getLuminance(pixel).toInt()]++;
    }
    return histo;
  }
  static img.Image applyEqualization(img.Image src) => img.histogramEqualization(src);
}