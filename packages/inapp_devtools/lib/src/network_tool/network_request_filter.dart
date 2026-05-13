import 'package:inapp_devtools/src/network_tool/network_profile_data.dart';

typedef NetworkProfileDataFilterPredicate =
    bool Function(NetworkProfileData profileData);

abstract class NetworkProfileDataFilter {
  String get label;

  final NetworkProfileDataFilterPredicate predicate;

  const NetworkProfileDataFilter._({required this.predicate});

  factory NetworkProfileDataFilter.includeDomains(Set<String> domains) {
    return DomainNetworkProfileDataFilter(
      domains.map((e) => e.toLowerCase()).toSet(),
      true,
    );
  }

  factory NetworkProfileDataFilter.excludeDomains(Set<String> domains) {
    return DomainNetworkProfileDataFilter(
      domains.map((e) => e.toLowerCase()).toSet(),
      false,
    );
  }

  factory NetworkProfileDataFilter.includeMethods(Set<String> methods) {
    return MethodNetworkProfileDataFilter(
      methods.map((e) => e.toLowerCase()).toSet(),
      true,
    );
  }

  factory NetworkProfileDataFilter.excludeMethods(Set<String> methods) {
    return MethodNetworkProfileDataFilter(
      methods.map((e) => e.toLowerCase()).toSet(),
      false,
    );
  }

  factory NetworkProfileDataFilter.includeStatusCodes(Set<int> statusCodes) {
    return StatusCodeNetworkProfileDataFilter(statusCodes, true);
  }

  factory NetworkProfileDataFilter.excludeStatusCodes(Set<int> statusCodes) {
    return StatusCodeNetworkProfileDataFilter(statusCodes, false);
  }

  factory NetworkProfileDataFilter.custom({
    required String label,
    required NetworkProfileDataFilterPredicate predicate,
  }) {
    return CustomNetworkProfileDataFilter(label: label, predicate: predicate);
  }

  bool matches(NetworkProfileData profileData) {
    return predicate(profileData);
  }
}

final class DomainNetworkProfileDataFilter extends NetworkProfileDataFilter {
  DomainNetworkProfileDataFilter(this.domains, this.include)
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

final class MethodNetworkProfileDataFilter extends NetworkProfileDataFilter {
  MethodNetworkProfileDataFilter(this.methods, this.include)
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

final class StatusCodeNetworkProfileDataFilter
    extends NetworkProfileDataFilter {
  StatusCodeNetworkProfileDataFilter(this.statusCodes, this.include)
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

class CustomNetworkProfileDataFilter extends NetworkProfileDataFilter {
  const CustomNetworkProfileDataFilter({
    required super.predicate,
    required this.label,
  }) : super._();
  @override
  final String label;
}
