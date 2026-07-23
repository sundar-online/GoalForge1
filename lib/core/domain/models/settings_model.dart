import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String theme; // 'light', 'dark', 'system'
  final String? dailyResetProcessed; // YYYY-MM-DD
  final String? weeklyIntentions;

  const AppSettings({
    this.theme = 'system',
    this.dailyResetProcessed,
    this.weeklyIntentions,
  });

  AppSettings copyWith({
    String? theme,
    String? dailyResetProcessed,
    String? weeklyIntentions,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      dailyResetProcessed: dailyResetProcessed ?? this.dailyResetProcessed,
      weeklyIntentions: weeklyIntentions ?? this.weeklyIntentions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'dailyResetProcessed': dailyResetProcessed,
      'weeklyIntentions': weeklyIntentions,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] as String? ?? 'system',
      dailyResetProcessed: json['dailyResetProcessed'] as String?,
      weeklyIntentions: json['weeklyIntentions'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory AppSettings.fromFirestore(Map<String, dynamic> data) => AppSettings.fromJson(data);

  bool isValid() => true;

  @override
  List<Object?> get props => [theme, dailyResetProcessed, weeklyIntentions];
}
