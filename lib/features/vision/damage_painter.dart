import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  // Gunakan nama 'mockBox' agar sinkron dengan panggilan di VisionView
  final Rect? mockBox; 
  final String label;

  DamagePainter({this.mockBox, this.label = "Searching..."});

  @override
  void paint(Canvas canvas, Size size) {
    // HOMEWORK: Implementasikan Skema Warna Dinamis [cite: 381-383]
    // Merah untuk Pothole (D40), Kuning untuk Crack (D00/D10/D20) 
    final isPothole = label.contains("D40");
    final themeColor = isPothole ? Colors.redAccent : Colors.yellowAccent;

    // 1. Konfigurasi "Kuas" Digital [cite: 271-273]
    final paint = Paint()
      ..color = themeColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 2. TASK 3: Menggambar Crosshair Statis (Visual Anchor) [cite: 132, 346]
    // Posisi tetap presisi di tengah layar (Rigid Positioning) [cite: 348]
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(center.dx - 20, center.dy), Offset(center.dx + 20, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 20), Offset(center.dx, center.dy + 20), paint);

    // 3. TASK 4: Menggambar Bounding Box Dinamis dengan Simulasi AI [cite: 356]
    if (mockBox != null) {
      // LOGIKA TRANSFORMASI: Memetakan normalisasi ke Logical Pixels [cite: 108-114, 357]
      final rect = Rect.fromLTWH(
        mockBox!.left * size.width,
        mockBox!.top * size.height,
        mockBox!.width * size.width,
        mockBox!.height * size.height,
      );

      canvas.drawRect(rect, paint); // [cite: 117]

      // 4. Rendering Label Intelijen (Text Painter) [cite: 277-280]
      final textPainter = TextPainter(
        text: TextSpan(
          text: " $label ",
          style: TextStyle(
            color: isPothole ? Colors.white : Colors.black,
            backgroundColor: themeColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(); // Proses Layouting sebelum rendering 

      // Gambar teks tepat di atas garis kotak (offset -20) [cite: 280]
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  // TASK 4: Diaktifkan (true) agar kotak bisa bergerak tanpa flicker [cite: 282-283, 360]
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}