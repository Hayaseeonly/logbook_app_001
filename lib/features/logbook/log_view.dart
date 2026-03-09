import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'log_editor_page.dart';
import 'widgets/log_item_widget.dart';
import '../../services/access_control_service.dart';
import '../onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final Map<String, dynamic> currentUser; 

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  late Future<void> _initialLoad;
  
  // Listener koneksi internet
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initialLoad = _controller.loadLogs(widget.currentUser['teamId']);
    
    // Memantau perubahan koneksi secara real-time
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isNowOffline = results.contains(ConnectivityResult.none);
      
      if (_isOffline && !isNowOffline) {
        _refreshData();
        // Cek mounted sebelum menggunakan BuildContext 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terhubung kembali! Menyinkronkan data..."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        setState(() => _isOffline = isNowOffline);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _initialLoad = _controller.loadLogs(widget.currentUser['teamId']);
    });
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
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

  void _confirmDelete(int originalIndex, LogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: Text("Yakin ingin menghapus '${log.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await _controller.removeLog(
                originalIndex, 
                widget.currentUser['role'], 
                widget.currentUser['uid']
              );
              
              // Cek mounted setelah operasi asinkron 
              if (!mounted) return;
              
              Navigator.pop(context);
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan": return Colors.blue.shade50;
      case "Urgent": return Colors.red.shade50;
      default: return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.currentUser['username']}"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Koneksi
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isOffline ? 30 : 0,
            color: Colors.redAccent,
            width: double.infinity,
            child: const Center(
              child: Text(
                "Mode Offline Aktif",
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Info Tim
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              "Tim: ${widget.currentUser['teamId']} | Role: ${widget.currentUser['role']}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => _controller.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder(
              future: _initialLoad,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _controller.logsNotifier.value.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ValueListenableBuilder(
                  valueListenable: _controller.logsNotifier,
                  builder: (context, List<LogModel> allLogs, _) => ValueListenableBuilder(
                    valueListenable: _controller.searchQueryNotifier,
                    builder: (context, query, _) {
                      final displayList = _controller.filteredLogs.where((log) {
                        return log.isPublic || log.authorId == widget.currentUser['uid'];
                      }).toList();

                      if (displayList.isEmpty) {
                        return const Center(child: Text("Belum ada catatan."));
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final log = displayList[index];
                            final int originalIndex = allLogs.indexOf(log);
                            final bool isOwner = log.authorId == widget.currentUser['uid'];

                            return LogItemWidget(
                              log: log,
                              backgroundColor: _getCategoryColor(log.category),
                              onEdit: AccessControlService.canPerform(
                                widget.currentUser['role'], 
                                'update', 
                                isOwner: isOwner
                              ) ? () => _goToEditor(log: log, index: originalIndex) : () {},
                              
                              onDelete: AccessControlService.canPerform(
                                widget.currentUser['role'], 
                                'delete', 
                                isOwner: isOwner
                              ) ? () => _confirmDelete(originalIndex, log) : () {},
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
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}