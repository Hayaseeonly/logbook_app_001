import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; 
  final String title;
  final String description;
  final String category; 
  final String date;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'category': category, 
      'date': date,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
      date: map['date'] ?? '',
    );
  }
}