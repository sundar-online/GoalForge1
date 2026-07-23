import 'package:equatable/equatable.dart';

class Memory extends Equatable {
  final String id;
  final String goalId;
  final String reflection;
  final String? photoURL;
  final String createdAt;

  const Memory({
    required this.id,
    required this.goalId,
    required this.reflection,
    this.photoURL,
    required this.createdAt,
  });

  Memory copyWith({
    String? id,
    String? goalId,
    String? reflection,
    String? photoURL,
    String? createdAt,
  }) {
    return Memory(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      reflection: reflection ?? this.reflection,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'reflection': reflection,
      'photoURL': photoURL,
      'createdAt': createdAt,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String? ?? '',
      goalId: json['goalId'] as String? ?? '',
      reflection: json['reflection'] as String? ?? '',
      photoURL: json['photoURL'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Memory.fromFirestore(Map<String, dynamic> data) => Memory.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && goalId.isNotEmpty && reflection.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, goalId, reflection, photoURL, createdAt];
}
