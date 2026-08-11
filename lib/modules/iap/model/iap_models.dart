class IapConfig {
  const IapConfig({
    required this.enabled,
    required this.platform,
    required this.revenueCatAppUserId,
  });

  final bool enabled;
  final String platform;
  final String revenueCatAppUserId;

  factory IapConfig.fromJson(Map<String, dynamic> json) {
    return IapConfig(
      enabled: json['enabled'] == true,
      platform: json['platform'] as String? ?? '',
      revenueCatAppUserId: json['revenuecatAppUserId'] as String? ?? '',
    );
  }
}

class CoursePurchaseOption {
  const CoursePurchaseOption({
    required this.owned,
    required this.state,
    this.mobileIap,
  });

  final bool owned;
  final String state;
  final MobileIapOption? mobileIap;

  bool get isAvailable => state == 'AVAILABLE' && mobileIap?.enabled == true;

  factory CoursePurchaseOption.fromJson(Map<String, dynamic> json) {
    return CoursePurchaseOption(
      owned: json['owned'] == true,
      state: json['state'] as String? ?? 'UNAVAILABLE',
      mobileIap:
          json['mobileIap'] is Map<String, dynamic>
              ? MobileIapOption.fromJson(
                json['mobileIap'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class MobileIapOption {
  const MobileIapOption({
    required this.enabled,
    this.productId,
    this.entitlementId,
  });

  final bool enabled;
  final String? productId;
  final String? entitlementId;

  factory MobileIapOption.fromJson(Map<String, dynamic> json) {
    return MobileIapOption(
      enabled: json['enabled'] == true,
      productId: json['productId'] as String?,
      entitlementId: json['entitlementId'] as String?,
    );
  }
}

class IapSyncResponse {
  const IapSyncResponse({
    required this.status,
    this.courseId,
    this.accessLevel,
    this.paymentMethod,
    this.activatedCourseIds = const [],
    this.unchangedCourseIds = const [],
  });

  final String status;
  final String? courseId;
  final String? accessLevel;
  final String? paymentMethod;
  final List<String> activatedCourseIds;
  final List<String> unchangedCourseIds;

  bool get isActive => status == 'ACTIVE' && accessLevel == 'FULL';
  bool get isPending => status == 'PENDING';

  factory IapSyncResponse.fromJson(Map<String, dynamic> json) {
    return IapSyncResponse(
      status: json['status'] as String? ?? 'PENDING',
      courseId: json['courseId']?.toString(),
      accessLevel: json['accessLevel'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      activatedCourseIds:
          (json['activatedCourseIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      unchangedCourseIds:
          (json['unchangedCourseIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class IapStatusResponse {
  const IapStatusResponse({
    required this.courseId,
    required this.accessLevel,
    required this.owned,
    this.source,
  });

  final String courseId;
  final String accessLevel;
  final bool owned;
  final String? source;

  factory IapStatusResponse.fromJson(Map<String, dynamic> json) {
    return IapStatusResponse(
      courseId: json['courseId']?.toString() ?? '',
      accessLevel: json['accessLevel'] as String? ?? 'FREE',
      owned: json['owned'] == true,
      source: json['source'] as String?,
    );
  }
}
