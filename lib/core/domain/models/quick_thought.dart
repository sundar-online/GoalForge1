import 'package:equatable/equatable.dart';

class QuickThought extends Equatable {
  final String id;
  final String content;
  final String createdAt;

  const QuickThought({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  QuickThought copyWith({
    String? id,
    String? content,
    String? createdAt,
  }) {
    return QuickThought(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory QuickThought.fromJson(Map<String, dynamic> json) {
    return QuickThought(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory QuickThought.fromFirestore(Map<String, dynamic> data) => QuickThought.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && content.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, content, createdAt];
}
