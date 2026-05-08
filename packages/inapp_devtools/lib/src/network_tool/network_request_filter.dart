import 'package:inapp_devtools/src/network_tool/http_profile_data.dart';

typedef NetworkRequestFilterPredicate =
    bool Function(HttpProfileData profileData);

abstract class NetworkRequestFilter {
  String get label;
  final NetworkRequestFilterPredicate predicate;

  const NetworkRequestFilter._({required this.predicate});

  factory NetworkRequestFilter.includeDomains(Set<String> domains) {
    return DomainNetworkRequestFilter(
      domains.map((e) => e.toLowerCase()).toSet(),
      true,
    );
  }

  factory NetworkRequestFilter.excludeDomains(Set<String> domains) {
    return DomainNetworkRequestFilter(
      domains.map((e) => e.toLowerCase()).toSet(),
      false,
    );
  }

  factory NetworkRequestFilter.includeMethods(Set<String> methods) {
    return MethodNetworkRequestFilter(
      methods.map((e) => e.toLowerCase()).toSet(),
      true,
    );
  }

  factory NetworkRequestFilter.excludeMethods(Set<String> methods) {
    return MethodNetworkRequestFilter(
      methods.map((e) => e.toLowerCase()).toSet(),
      false,
    );
  }

  factory NetworkRequestFilter.includeStatusCodes(Set<int> statusCodes) {
    return StatusCodeNetworkRequestFilter(statusCodes, true);
  }

  factory NetworkRequestFilter.excludeStatusCodes(Set<int> statusCodes) {
    return StatusCodeNetworkRequestFilter(statusCodes, false);
  }

  factory NetworkRequestFilter.custom({
    required String label,
    required NetworkRequestFilterPredicate predicate,
  }) {
    return CustomNetworkRequestFilter(label: label, predicate: predicate);
  }

  bool matches(HttpProfileData profileData) {
    return predicate(profileData);
  }
}

final class DomainNetworkRequestFilter extends NetworkRequestFilter {
  DomainNetworkRequestFilter(this.domains, this.include)
    : super._(
        predicate: include
            ? (profileData) {
                return domains.contains(profileData.uri.host.toLowerCase());
              }
            : (profileData) {
                return !domains.contains(profileData.uri.host.toLowerCase());
              },
      );
  @override
  String get label => 'Domain';

  final bool include;

  final Set<String> domains;
}

final class MethodNetworkRequestFilter extends NetworkRequestFilter {
  MethodNetworkRequestFilter(this.methods, this.include)
    : super._(
        predicate: include
            ? (profileData) {
                return methods.contains(profileData.method.toLowerCase());
              }
            : (profileData) {
                return !methods.contains(profileData.method.toLowerCase());
              },
      );
  @override
  String get label => 'Method';

  final bool include;

  final Set<String> methods;
}

final class StatusCodeNetworkRequestFilter extends NetworkRequestFilter {
  StatusCodeNetworkRequestFilter(this.statusCodes, this.include)
    : super._(
        predicate: include
            ? (profileData) {
                return statusCodes.contains(profileData.response.statusCode);
              }
            : (profileData) {
                return !statusCodes.contains(profileData.response.statusCode);
              },
      );
  @override
  String get label => 'Status Code';

  final bool include;

  final Set<int?> statusCodes;
}

class CustomNetworkRequestFilter extends NetworkRequestFilter {
  const CustomNetworkRequestFilter({
    required super.predicate,
    required this.label,
  }) : super._();
  @override
  final String label;
}
