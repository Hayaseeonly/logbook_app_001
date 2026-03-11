import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscure = true; 

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username dan Password harus diisi!")),
      );
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => LogView(
        currentUser: {
          'uid': user.toLowerCase().contains('admin') ? 'ID_ADMIN_01' : 'ID_MAHASISWA_01',
          'username': user,
          'role': user.toLowerCase().contains('admin') ? 'Ketua' : 'Anggota',
          'teamId': 'MEKTRA_KLP_01',
        },
      ),
      ),
      );
    } else {
      String message = _controller.isLocked 
          ? "Terlalu banyak percobaan! Tunggu 10 detik." 
          : "Login Gagal! Cek kembali username/password.";
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _controller.isLocked ? null : _handleLogin, 
                child: Text(_controller.isLocked ? "Terkunci (10s)" : "Masuk"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}