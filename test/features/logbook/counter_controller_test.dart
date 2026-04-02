import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';

void main() {
  // Diperlukan agar SharedPreferences bisa di-mock saat Unit Testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CounterController - Unit Testing (TC01 - TC10)', () {
    late CounterController controller;

    setUp(() {
      // Inisialisasi SharedPreferences dengan data kosong sebelum setiap test
      SharedPreferences.setMockInitialValues({});
      controller = CounterController();
    });

    // TC01: Initial Value
    test('TC01 - loadCounter should set initial value to 0', () async {
      await controller.loadSavedData("admin");
      expect(controller.value, 0);
    });

    // TC02: SetStep Positif
    test('TC02 - setStep should change step value', () {
      controller.setStep(5);
      expect(controller.step, 5);
    });

    // TC03: SetStep Negatif (Edge Case)
    test('TC03 - setStep should ignore negative value', () {
      controller.setStep(3); // Nilai sebelumnya 3
      controller.setStep(-1); // Input negatif
      // Jika logika setStep sudah diperbaiki, maka harus tetap 3
      expect(controller.step, 3); 
    });

    // TC04: Increment
    test('TC04 - increment should increase value by step', () {
      controller.increment(); 
      expect(controller.value, 1);
    });

    // TC05: Decrement Normal
    test('TC05 - decrement should decrease value by step', () {
      controller.increment(); // jadi 1
      controller.decrement(); // jadi 0
      expect(controller.value, 0);
    });

    // TC06: Decrement Negative (Edge Case Paling Penting Modul 6)
    test('TC06 - decrement should not result in negative value', () {
      controller.decrement(); 
      expect(controller.value, 0);
    });

    // TC07: Reset
    test('TC07 - reset should return value to 0 and step to 1', () {
      controller.setStep(5);
      controller.increment();
      controller.reset();
      expect(controller.value, 0);
      expect(controller.step, 1);
    });

    // TC08: History Limit
    test('TC08 - history should keep max 5 entries', () {
      for (int i = 0; i < 10; i++) controller.increment();
      expect(controller.history.length, 5);
    });

    // TC09: History Integrity
    test('TC09 - history entry type should match last action', () {
      controller.reset();
      expect(controller.history.first.type, LogType.reset);
    });

    // TC10: Welcome Message
    test('TC10 - welcomeMessage should contain active username', () async {
      await controller.loadSavedData("admin");
      expect(controller.welcomeMessage, contains("admin"));
    });
  });
}