import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String date;
  @HiveField(4)
  final String authorId;
  @HiveField(5)
  final String teamId;
  @HiveField(6)
  final bool isPublic;
  @HiveField(7)
  final String category;
  
  // Field tambahan untuk identitas di UI
  @HiveField(8)
  final String authorName;
  @HiveField(9)
  final String authorRole;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false,
    this.category = 'Pribadi',
    this.authorName = 'User',
    this.authorRole = 'Anggota',
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'description': description,
      'date': date,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
      'category': category,
      'authorName': authorName,
      'authorRole': authorRole,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
      category: map['category'] ?? 'Pribadi',
      authorName: map['authorName'] ?? 'Unknown',
      authorRole: map['authorRole'] ?? 'Anggota',
    );
  }
}