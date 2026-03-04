import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart'; 

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // 1. Tambahkan PageController untuk mengontrol swipe
  final PageController _pageController = PageController();
  int _currentPage = 0; // PageView dimulai dari index 0

  @override
  void dispose() {
    _pageController.dispose(); // Selalu hapus controller saat tidak dipakai
    super.dispose();
  }

  void _nextStep() {
    if (_currentPage < 2) {
      // Pindah ke halaman berikutnya dengan animasi slide
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    } else {
      // Jika sudah halaman terakhir, pindah ke Login
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginView())
      );
    }
  }

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/Logo.jpeg",
      "title": "Selamat datang di Logbook App",
    },
    {
      "image": "assets/Book.jpeg",
      "title": "Catat aktifitas harianmu dengan mudah",
    },
    {
      "image": "assets/Lock.jpeg",
      "title": "Data dan Riwayat tersimpan aman di perangkat",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            // 2. Expanded & PageView agar area atas bisa di-scroll
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(onboardingData[index]["image"]!, height: 250),
                        const SizedBox(height: 30),
                        Text(
                          onboardingData[index]["title"]!, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 3. Page Indicator 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 10,
                width: index == _currentPage ? 25 : 10, // Efek memanjang jika aktif
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: index == _currentPage ? Colors.blue : Colors.grey.shade300,
                ),
              )),
            ),
            
            const SizedBox(height: 40),
            
            // 4. Tombol Dinamis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextStep, 
                  child: Text(_currentPage == 2 ? "Masuk" : "Lanjut"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}