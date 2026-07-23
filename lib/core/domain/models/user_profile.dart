import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    String? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoURL: json['photoURL'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory UserProfile.fromFirestore(Map<String, dynamic> data) => UserProfile.fromJson(data);

  bool isValid() {
    return uid.isNotEmpty && displayName.isNotEmpty && email.isNotEmpty;
  }

  @override
  List<Object?> get props => [uid, displayName, email, photoURL, createdAt];
}
