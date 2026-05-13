sealed class AnalyticsProfileData {
  const AnalyticsProfileData({
    required this.loggedAt,
    this.canShowDateTime = true,
  });

  final DateTime loggedAt;
  final bool canShowDateTime;

  factory AnalyticsProfileData.event({
    required String name,
    required DateTime loggedAt,
    Map<String, Object?>? parameters,
    bool canShowDateTime,
  }) = Event;

  factory AnalyticsProfileData.screenView({
    required String screenName,
    required DateTime loggedAt,
    Map<String, Object?>? parameters,
    bool canShowDateTime,
  }) = ScreenView;

  factory AnalyticsProfileData.globalParameters({
    required Map<String, Object?> parameters,
    required DateTime loggedAt,
    bool canShowDateTime,
  }) = GlobalParameters;

  factory AnalyticsProfileData.userId({
    required String? userId,
    required DateTime loggedAt,
    bool canShowDateTime,
  }) = UserId;

  factory AnalyticsProfileData.userProperty({
    required String name,
    required DateTime loggedAt,
    Object? value,
    bool canShowDateTime,
  }) = UserProperty;
}

final class Event extends AnalyticsProfileData {
  const Event({
    required this.name,
    required super.loggedAt,
    this.parameters,
    super.canShowDateTime,
  });

  final String name;
  final Map<String, Object?>? parameters;
}

final class ScreenView extends AnalyticsProfileData {
  const ScreenView({
    required this.screenName,
    required super.loggedAt,
    this.parameters,
    super.canShowDateTime,
  });

  final String screenName;
  final Map<String, Object?>? parameters;
}

final class GlobalParameters extends AnalyticsProfileData {
  const GlobalParameters({
    required this.parameters,
    required super.loggedAt,
    super.canShowDateTime,
  });

  final Map<String, Object?> parameters;
}

final class UserId extends AnalyticsProfileData {
  const UserId({
    required this.userId,
    required super.loggedAt,
    super.canShowDateTime,
  });

  final String? userId;
}

final class UserProperty extends AnalyticsProfileData {
  const UserProperty({
    required this.name,
    required super.loggedAt,
    this.value,
    super.canShowDateTime,
  });

  final String name;
  final Object? value;
}
