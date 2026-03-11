import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix dasar perizinan
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
  };

  /// Fungsi Gatekeeper yang diperbarui (Ketua bisa edit semua)
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // LOGIKA PERBAIKAN:
    // Jika aksinya adalah Update atau Delete, izinkan JIKA:
    // 1. Dia adalah pemilik asli (isOwner) 
    // 2. ATAU dia adalah 'Ketua' (Role Master)
    if (action == actionUpdate || action == actionDelete) {
      return isOwner || role == 'Ketua'; 
    }

    // Untuk Create dan Read tetap menggunakan matrix role
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }

  /// Helper untuk pengecekan ID (tetap sama)
  static bool checkOwnership(String? logAuthorId, String? currentUserId) {
    if (logAuthorId == null || currentUserId == null) return false;
    if (logAuthorId == 'unknown' || logAuthorId.isEmpty) return false;
    return logAuthorId == currentUserId;
  }
}