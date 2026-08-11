class LoginSocialResponse {
  LoginSocialResponse({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.image,
    this.accessToken,
    this.refreshToken,
    this.role,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? image;
  final String? accessToken;
  final String? refreshToken;
  final String? role;

  factory LoginSocialResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return LoginSocialResponse(
      id: user["id"]?.toString() ?? json["id"]?.toString(),
      name: user["full_name"] as String? ??
          user["username"] as String? ??
          json["name"] as String?,
      email: user["email"] as String? ?? json["email"] as String?,
      phone: user["phone"] as String? ?? json["phone"] as String?,
      image: user["avatar_url"] as String? ?? json["image"] as String?,
      accessToken: json["access_token"] as String? ?? json["accessToken"] as String?,
      refreshToken: json["refresh_token"] as String? ?? json["refreshToken"] as String?,
      role: user["role"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "image": image,
    "accessToken": accessToken,
    "refreshToken": refreshToken,
    "role": role,
  };

  @override
  String toString() {
    return "$id, $name, $email, $phone, $image, $accessToken, $refreshToken, ";
  }
}
