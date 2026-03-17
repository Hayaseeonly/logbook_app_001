import 'package:flutter/material.dart';
import 'counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  late Future<void> _initialLoad;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    // Inisialisasi pengambilan data dari Cloud
    _initialLoad = _controller.loadSavedData(widget.username);
  }

  // Fungsi untuk refresh data 
  Future<void> _refreshData() async {
    setState(() {
      _initialLoad = _controller.loadSavedData(widget.username);
    });
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.tambah: return Colors.green;
      case LogType.kurang: return Colors.red;
      case LogType.reset: return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              );
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Reset"),
        content: const Text("Apakah Anda yakin ingin menghapus semua hitungan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              _controller.reset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hitungan telah direset!")),
              );
            },
            child: const Text("Ya, Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: FutureBuilder(
        future: _initialLoad,
        builder: (context, snapshot) {
          //  Menghubungkan ke MongoDB Atlas
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Sedang menghubungkan ke DB Atlas...", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            );
          }

          // Offline Mode
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.red),
                  const Center(
                    child: Text("Tidak Ada Koneksi Internet", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Gagal mengambil data hitungan dari Cloud.", textAlign: TextAlign.center),
                  ),
                  Center(
                    child: ElevatedButton(onPressed: _refreshData, child: const Text("Coba Lagi")),
                  ),
                ],
              ),
            );
          }

          // 3. SUCCESS STATE: Tampilan Counter
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  // Banner Welcome
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _controller.welcomeMessage,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Total Hitungan:", style: TextStyle(fontSize: 14)),
                  Text(
                    '${_controller.value}',
                    style: const TextStyle(fontSize: 55, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Nilai Step",
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.unfold_more, size: 20),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (input) {
                      int? val = int.tryParse(input);
                      if (val != null) _controller.setStep(val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _controller.decrement,
                          child: const Text("- Kurang", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _controller.increment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("+ Tambah", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirmReset,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                          child: const Text("↻ Reset", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text("Riwayat Aktivitas", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Riwayat List
                  _controller.history.isEmpty
                      ? const Text("Belum ada riwayat.", style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _controller.history.length,
                          itemBuilder: (context, index) {
                            final log = _controller.history[index];
                            final Color logColor = _getLogColor(log.type);
                            return Card(
                              elevation: 0,
                              color: logColor.withOpacity(0.05),
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.history, color: logColor, size: 16),
                                title: Text(log.message,
                                    style: TextStyle(color: logColor, fontWeight: FontWeight.w500, fontSize: 12)),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}