import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    if (action == actionUpdate || action == actionDelete) {
      return isOwner || role == 'Ketua'; 
    }
    
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }

  static bool checkOwnership(String? logAuthorId, String? currentUserId) {
    if (logAuthorId == null || currentUserId == null) return false;
    if (logAuthorId == 'unknown' || logAuthorId.isEmpty) return false;
    return logAuthorId == currentUserId;
  }
}