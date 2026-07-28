import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/badge_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class SelectBadgeCategoryTab extends ProfileEvent {
  final BadgeCategory? category; // null for 'ALL'

  const SelectBadgeCategoryTab(this.category);

  @override
  List<Object?> get props => [category];
}

class ToggleSmartNotificationsSetting extends ProfileEvent {
  final bool enabled;

  const ToggleSmartNotificationsSetting(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ClearAllProfileDataRequested extends ProfileEvent {
  const ClearAllProfileDataRequested();
}
