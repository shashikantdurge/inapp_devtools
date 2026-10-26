import 'dart:convert';

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

  String beautifyContentForCopy();
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

  @override
  String beautifyContentForCopy() {
    String? parametersString;
    if (parameters != null) {
      try {
        parametersString = JsonEncoder.withIndent('\t').convert(parameters);
      } catch (_) {
        parametersString = parameters?.toString();
      }
      parametersString = '\n$parametersString';
    }
    return '${loggedAt.toIso8601String()}\nevent - $name${parametersString ?? ''}';
  }
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

  @override
  String beautifyContentForCopy() {
    String? parametersString;
    if (parameters != null) {
      try {
        parametersString = JsonEncoder.withIndent('\t').convert(parameters);
      } catch (_) {
        parametersString = parameters?.toString();
      }
      parametersString = '\n$parametersString';
    }
    return '${loggedAt.toIso8601String()}\nscreen_view - $screenName${parametersString ?? ''}';
  }
}

final class GlobalParameters extends AnalyticsProfileData {
  const GlobalParameters({
    required this.parameters,
    required super.loggedAt,
    super.canShowDateTime,
  });

  final Map<String, Object?> parameters;

  @override
  String beautifyContentForCopy() {
    String parametersString;
    try {
      parametersString = JsonEncoder.withIndent('\t').convert(parameters);
    } catch (_) {
      parametersString = parameters.toString();
    }
    return '${loggedAt.toIso8601String()}\nglobal_parameters\n$parametersString';
  }
}

final class UserId extends AnalyticsProfileData {
  const UserId({
    required this.userId,
    required super.loggedAt,
    super.canShowDateTime,
  });

  final String? userId;

  @override
  String beautifyContentForCopy() {
    return '${loggedAt.toIso8601String()}\nuser_id - $userId';
  }
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

  @override
  String beautifyContentForCopy() {
    return '${loggedAt.toIso8601String()}\nuser_property - $name: $value';
  }
}
