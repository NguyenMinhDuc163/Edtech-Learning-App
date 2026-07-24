import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sp_util/sp_util.dart';

const String _userDataKey = 'user_data';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance!;

  static Future<UserService> initialize() async {
    _instance ??= UserService._();
    await _instance!._loadUserData();
    return _instance!;
  }

  UserService._();

  UserData? _userData;
  UserData? get userData => _userData;

  final userDataNotifier = ValueNotifier<UserData?>(null);

  Future<void> _loadUserData() async {
    final String? userJson = SpUtil.getString(_userDataKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(userJson);
        _userData = UserData.fromJson(json);
        userDataNotifier.value = _userData;
      } catch (e) {
        _userData = null;
        userDataNotifier.value = null;
      }
    }
  }

  Future<void> saveUserData(UserData user) async {
    _userData = user;
    userDataNotifier.value = user;
    final String userJson = jsonEncode(user.toJson());
    await SpUtil.putString(_userDataKey, userJson);
  }

  Future<void> clearUserData() async {
    _userData = null;
    userDataNotifier.value = null;
    await SpUtil.remove(_userDataKey);
  }

  String get displayName => _userData?.username ?? 'User';
  String get email => _userData?.email ?? '';
  String get role => _userData?.role ?? 'student';
  String? get isPayment => _userData?.isPayment;


  /// Whether the server has explicitly disabled ads for this user.
  /// `true` only when `isAds == "N"` (VIP/premium).
  /// `false` for `null` or any other value (backward compatible:
  /// if the server hasn't rolled out this field, ads stay enabled).
  bool get showAds => _userData?.isAds != 'N';
}

class UserData {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? isPayment;
  final String? isAds;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? grade;
  final String? subjectSpecialty;
  final List<CertificateData>? certificates;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isPayment,
    this.isAds,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.grade,
    this.subjectSpecialty,
    this.certificates,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      isPayment: json['isPayment'],
      isAds: json['isAds'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      phone: json['phone'],
      grade: json['grade'],
      subjectSpecialty: json['subjectSpecialty'],
      certificates: json['certificates'] == null
        ? null
        : List<CertificateData>.from(json['certificates'].map((x) => CertificateData.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'isPayment': isPayment,
      'isAds': isAds,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'grade': grade,
      'subjectSpecialty': subjectSpecialty,
      'certificates': certificates?.map((x) => x.toJson()).toList(),
    };
  }
}

class CertificateData {
  final String? id;
  final String? title;
  final String? description;
  final String? issuedBy;
  final String? issuedAt;
  final String? expiresAt;
  final String? fileUrl;
  final String? createdAt;
  final String? updatedAt;

  CertificateData({
    this.id,
    this.title,
    this.description,
    this.issuedBy,
    this.issuedAt,
    this.expiresAt,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory CertificateData.fromJson(Map<String, dynamic> json) {
    return CertificateData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      issuedBy: json['issuedBy'],
      issuedAt: json['issuedAt'],
      expiresAt: json['expiresAt'],
      fileUrl: json['fileUrl'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'issuedBy': issuedBy,
      'issuedAt': issuedAt,
      'expiresAt': expiresAt,
      'fileUrl': fileUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
