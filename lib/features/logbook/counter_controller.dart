import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

enum LogType { tambah, kurang, reset }

class LogEntry {
  final String message;
  final LogType type;

  LogEntry(this.message, this.type);
}

class CounterController extends ChangeNotifier {
  int _counter = 0;
  int _step = 1;
  List<LogEntry> _history = [];
  String _currentUsername = "";

  int get value => _counter;
  int get step => _step;
  List<LogEntry> get history => _history;

  // Menentukan sapaan berdasarkan waktu
  String get welcomeMessage {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour >= 6 && hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return "$greeting, $_currentUsername!";
  }

  // Simpan data spesifik per-user
  Future<void> _saveData() async {
    if (_currentUsername.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter_${_currentUsername}', _counter);
    
    List<String> historyStrings = _history.map((e) => "${e.message}|${e.type.index}").toList();
    await prefs.setStringList('history_${_currentUsername}', historyStrings);
  }

  // Muat data spesifik per-user
  Future<void> loadSavedData(String username) async {
    _currentUsername = username;
    final prefs = await SharedPreferences.getInstance();
    
    _counter = prefs.getInt('counter_$username') ?? 0;
    
    List<String> historyStrings = prefs.getStringList('history_$username') ?? [];
    _history = historyStrings.map((item) {
      var parts = item.split('|');
      return LogEntry(parts[0], LogType.values[int.parse(parts[1])]);
    }).toList();
    
    notifyListeners();
  }

  void setStep(int newValue) {
    _step = newValue;
    notifyListeners();
  }

  void increment() {
    _counter += _step;
    _addLog("ditambah $_step nilai", LogType.tambah);
    _saveData();
    notifyListeners();
  }

  void decrement() {
    _counter -= _step;
    _addLog("dikurang $_step nilai", LogType.kurang);
    _saveData();
    notifyListeners();
  }

  void reset() {
    _counter = 0;
    _step = 1;
    _addLog("direset ke 0", LogType.reset);
    _saveData();
    notifyListeners();
  }

  void _addLog(String actionDescription, LogType type) {
    final now = DateTime.now();
    final String timeStr = 
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    final String logMessage = "($actionDescription pada pukul $timeStr)";

    _history.insert(0, LogEntry(logMessage, type));
    if (_history.length > 5) _history.removeLast();
  }
}