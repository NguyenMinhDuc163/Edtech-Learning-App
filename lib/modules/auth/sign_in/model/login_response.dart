class LoginResponse {
  LoginResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  final num? status;
  final String? message;
  final Data? data;

  factory LoginResponse.fromJson(Map<String, dynamic> json){
    return LoginResponse(
      status: json["status"],
      message: json["message"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };

  @override
  String toString(){
    return "$status, $message, $data, ";
  }
}

class Data {
  Data({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.isPayment,
    this.isAds,
  });

  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final String? isPayment;

  /// Server-controlled ad eligibility flag.
  /// `"N"` means ads are disabled (VIP/premium user).
  /// `null` or any other value means ads are enabled (free user, or
  /// server hasn't implemented this field yet — backward compatible).
  final String? isAds;

  factory Data.fromJson(Map<String, dynamic> json){
    return Data(
      accessToken: json["access_token"],
      refreshToken: json["refresh_token"],
      user: json["user"] == null ? null : User.fromJson(json["user"]),
      isPayment: json["isPayment"],
      isAds: json["isAds"],
    );
  }

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "user": user?.toJson(),
    "isPayment": isPayment,
    "isAds": isAds,
  };

  @override
  String toString(){
    return "$accessToken, $refreshToken, $user, $isPayment, $isAds, ";
  }
}

class User {
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.grade,
    this.subjectSpecialty,
    this.certificates,
  });

  final String? id;
  final String? username;
  final String? email;
  final String? role;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? grade;
  final String? subjectSpecialty;
  final List<Certificate>? certificates;

  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      role: json["role"],
      fullName: json["full_name"],
      avatarUrl: json["avatar_url"],
      phone: json["phone"],
      grade: json["grade"],
      subjectSpecialty: json["subject_specialty"],
      certificates: json["certificates"] == null
        ? null
        : List<Certificate>.from(json["certificates"].map((x) => Certificate.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "email": email,
    "role": role,
    "full_name": fullName,
    "avatar_url": avatarUrl,
    "phone": phone,
    "grade": grade,
    "subject_specialty": subjectSpecialty,
    "certificates": certificates?.map((x) => x.toJson()).toList(),
  };

  @override
  String toString(){
    return "$id, $username, $email, $role, ";
  }
}

class Certificate {
  Certificate({
    required this.id,
    required this.title,
    this.description,
    this.issuedBy,
    this.issuedAt,
    this.expiresAt,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? title;
  final String? description;
  final String? issuedBy;
  final String? issuedAt;
  final String? expiresAt;
  final String? fileUrl;
  final String? createdAt;
  final String? updatedAt;

  factory Certificate.fromJson(Map<String, dynamic> json){
    return Certificate(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      issuedBy: json["issued_by"],
      issuedAt: json["issued_at"],
      expiresAt: json["expires_at"],
      fileUrl: json["file_url"],
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "issued_by": issuedBy,
    "issued_at": issuedAt,
    "expires_at": expiresAt,
    "file_url": fileUrl,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
