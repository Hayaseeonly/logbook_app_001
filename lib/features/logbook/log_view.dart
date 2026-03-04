// lib/features/logbook/log_view.dart
import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'widgets/log_item_widget.dart'; 
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart'; 

class LogView extends StatefulWidget {
  final String username; 
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  final List<String> _categories = ["Pribadi", "Pekerjaan", "Urgent"];
  String _selectedCategory = "Pribadi";

  late Future<void> _initialLoad;

  @override
  void initState() {
    super.initState();
    _initialLoad = _controller.loadFromDisk(); 
  }

  // Fungsi refresh yang memicu loading ulang secara visual
  Future<void> _refreshData() async {
    setState(() {
      _initialLoad = _controller.loadFromDisk();
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan": return Colors.blue.shade50;
      case "Urgent": return Colors.red.shade50;
      default: return Colors.green.shade50;
    }
  }

  // ... (fungsi _confirmDelete, _handleLogout, dan _showLogDialog tetap sama)

  void _confirmDelete(int originalIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: const Text("Apakah Anda yakin ingin menghapus catatan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await _controller.removeLog(originalIndex);
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Catatan berhasil dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _showLogDialog({int? index, LogModel? log}) {
    if (log != null) {
      _titleController.text = log.title;
      _descController.text = log.description;
      _selectedCategory = log.category;
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedCategory = "Pribadi";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? "Tambah Catatan" : "Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(hintText: "Judul")),
              TextField(controller: _descController, decoration: const InputDecoration(hintText: "Deskripsi")),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: "Pilih Kategori", border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => _selectedCategory = val as String),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (index == null) {
                  await _controller.addLog(_titleController.text, _descController.text, _selectedCategory);
                } else {
                  await _controller.updateLog(index, _titleController.text, _descController.text, _selectedCategory);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"), 
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => _controller.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Cari judul catatan...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder(
              future: _initialLoad,
              builder: (context, snapshot) {
                // --- 1. STATE: SEDANG MENGHUBUNGKAN (Loading Informatif)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text(
                          "Sedang menghubungkan ke DB Atlas...",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  );
                }

                // --- 2. STATE: OFFLINE / ERROR 
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(), 
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        const Icon(Icons.wifi_off_rounded, size: 100, color: Colors.redAccent),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text("Koneksi Internet Terputus",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(25.0),
                          child: Text(
                            "Gagal menghubungi MongoDB Atlas. Cek kuota atau WiFi-mu, lalu tarik layar ke bawah untuk coba lagi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Coba Lagi Sekarang"),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // --- 3. STATE: BERHASIL ---
                return ValueListenableBuilder(
                  valueListenable: _controller.logsNotifier,
                  builder: (context, List<LogModel> allLogs, _) => ValueListenableBuilder(
                    valueListenable: _controller.searchQueryNotifier,
                    builder: (context, _, __) {
                      final displayList = _controller.filteredLogs;

                      if (displayList.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Icon(Icons.cloud_done_outlined, size: 80, color: Colors.grey),
                              const Center(child: Text("Data Kosong di Cloud")),
                              const Center(child: Text("Tarik untuk cek ulang", style: TextStyle(fontSize: 10))),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final log = displayList[index];
                            final int originalIndex = allLogs.indexOf(log);
                            final Color cardColor = _getCategoryColor(log.category);

                            return LogItemWidget(
                              log: log,
                              backgroundColor: cardColor,
                              onEdit: () => _showLogDialog(index: originalIndex, log: log),
                              onDelete: () => _confirmDelete(originalIndex),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}