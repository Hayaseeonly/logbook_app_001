import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final Map<String, String> _users = {
    "admin": "123",
    "mahasiswa": "polban",
  };

  int _wrongAttempts = 0;
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  bool login(String username, String password) {
    if (_isLocked) return false;

    if (_users.containsKey(username) && _users[username] == password) {
      _wrongAttempts = 0;
      return true;
    } else {
      _wrongAttempts++;
      // Jika salah 3 kali, kunci tombol 
      if (_wrongAttempts >= 3) {
        _lockButton();
      }
      return false;
    }
  }

  void _lockButton() {
    _isLocked = true;
    notifyListeners();
    
    // Tunggu 10 detik lalu buka lagi 
    Future.delayed(const Duration(seconds: 10), () {
      _isLocked = false;
      _wrongAttempts = 0;
      notifyListeners();
    });
  }
}