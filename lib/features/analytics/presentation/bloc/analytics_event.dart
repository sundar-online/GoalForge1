import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToAnalytics extends AnalyticsEvent {}

class SelectTimeframeEvent extends AnalyticsEvent {
  final String timeframe; // 'Weekly', 'Monthly'

  const SelectTimeframeEvent(this.timeframe);

  @override
  List<Object?> get props => [timeframe];
}
