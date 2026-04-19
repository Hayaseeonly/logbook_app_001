import 'package:image/image.dart' as img;

class PcdService {
  // 1. Grayscale
  static img.Image applyGrayscale(img.Image src) => img.grayscale(src);

  // 2. Biner (Thresholding)
  static img.Image applyBiner(img.Image src, {int threshold = 128}) => 
      img.luminanceThreshold(src, threshold: threshold / 255);

  // 3. Inverse
  static img.Image applyInverse(img.Image src) => img.invert(src);

  // 4. Low Pass (Smoothing)
  static img.Image applyLowPass(img.Image src) => img.gaussianBlur(src, radius: 2);

  // 5. High Pass (Sharpening/Laplacian)
  static img.Image applyHighPass(img.Image src) => 
      img.convolution(src, filter: [-1, -1, -1, -1, 8, -1, -1, -1, -1]);

  // 6. Band Pass (Difference of Gaussians)
  static img.Image applyBandPass(img.Image src) {
    final blur1 = img.gaussianBlur(src, radius: 2);
    final blur2 = img.gaussianBlur(src, radius: 8);
    // Mengurangi hasil blur rendah dengan blur tinggi untuk mengambil rentang tengah
    return img.compositeImage(blur1, blur2, blend: img.BlendMode.difference);
  }

  // 7. Mean Filter
  static img.Image applyMean(img.Image src) => 
      img.convolution(src, filter: [1, 1, 1, 1, 1, 1, 1, 1, 1], div: 9);


  // 9. Gaussian
  static img.Image applyGaussian(img.Image src) => img.gaussianBlur(src, radius: 3);

  // 10. Histogram Equalization
  static img.Image applyHistogramEqualization(img.Image src) => img.histogramEqualization(src);

  // 11. Adaptive Histogram Equalization (Simulasi AHE sederhana)
  static img.Image applyAdaptiveHistogram(img.Image src) {
    // Catatan: Library image standar belum mendukung CLAHE/AHE secara native, 
    // kita gunakan Equalization sebagai representasi dasar di modul ini.
    return img.histogramEqualization(src); 
  }

  // 12. Histogram Specification (Placeholder/Simplified)
  static img.Image applyHistogramSpecification(img.Image src) {
    // Proses penyesuaian histogram ke distribusi tertentu (misal: normal)
    return img.contrast(src, contrast: 1.5); // Penyesuaian kontras sebagai pendekatan
  }
}