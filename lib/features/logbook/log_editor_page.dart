import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final Map<String, dynamic> currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;
  bool _isPublic = false;

  final List<String> _categories = ["Pribadi", "Pekerjaan", "Urgent"];

  @override
  void initState() {
    super.initState();
    // Mengambil data lama jika dalam mode Edit 
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? "Pribadi";
    _isPublic = widget.log?.isPublic ?? false;

    // Listener agar tab pratinjau langsung update secara real-time saat mengetik
    _descController.addListener(() {
      setState(() {});
    });
  }

   void _handleSave() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul tidak boleh kosong!")),
      );
      return;
    }

    try {
      if (widget.log == null) {
        // Parameter 'user'
        await widget.controller.addLog(
          _titleController.text,
          _descController.text,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
          category: _selectedCategory,
          isPublic: _isPublic,
          user: widget.currentUser, 
        );
      } else {
        await widget.controller.updateLog(
        widget.index!,              
        _titleController.text,      
        _descController.text,       
        widget.currentUser['uid'],  
        widget.currentUser['role'], 
        category: _selectedCategory,
        isPublic: _isPublic,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          actions: [
            // Switch untuk Pengaturan Privasi (Public/Private)
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                const Text("Public", style: TextStyle(fontSize: 12)),
                Switch(
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _handleSave,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            //  AREA EDITOR (Input Teks)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Judul",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val as String),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 15,
                    decoration: const InputDecoration(
                      hintText: "Gunakan Markdown (# Judul, **Tebal**, - List)...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            // Render format Markdown secara real-time
            Markdown(
              data: _descController.text.isEmpty
                  ? "# Kosong\n_Belum ada konten untuk dipratinjau._"
                  : _descController.text,
              selectable: true,
            ),
          ],
        ),
      ),
    );
  }
}