import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool completed;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.completed = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? completed,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, text, completed];
}

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<ChecklistItem> checklist;
  final List<String> tags;
  final String folder;
  final bool pinned;
  final int? color; // Holds color value as integer, e.g. 0xFF4CAF50
  final String createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.checklist,
    required this.tags,
    required this.folder,
    this.pinned = false,
    this.color,
    required this.createdAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<ChecklistItem>? checklist,
    List<String>? tags,
    String? folder,
    bool? pinned,
    int? color,
    String? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      checklist: checklist ?? this.checklist,
      tags: tags ?? this.tags,
      folder: folder ?? this.folder,
      pinned: pinned ?? this.pinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'tags': tags,
      'folder': folder,
      'pinned': pinned,
      'color': color,
      'createdAt': createdAt,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    var checklistList = json['checklist'] as List? ?? [];
    return Note(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      checklist: checklistList
          .map((item) => ChecklistItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      folder: json['folder'] as String? ?? 'General',
      pinned: json['pinned'] as bool? ?? false,
      color: json['color'] as int?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Note.fromFirestore(Map<String, dynamic> data) => Note.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        checklist,
        tags,
        folder,
        pinned,
        color,
        createdAt,
      ];
}
