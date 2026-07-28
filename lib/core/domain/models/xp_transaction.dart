import 'package:equatable/equatable.dart';

class XpTransaction extends Equatable {
  final String id;
  final String title;
  final int amount;
  final String timestamp;
  final String type; // 'task', 'habit', 'perfect_day', 'streak', 'goal', 'focus'

  const XpTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'timestamp': timestamp,
        'type': type,
      };

  factory XpTransaction.fromJson(Map<String, dynamic> json) => XpTransaction(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        timestamp: json['timestamp'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
      );

  @override
  List<Object?> get props => [id, title, amount, timestamp, type];
}
