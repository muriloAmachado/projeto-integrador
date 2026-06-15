class LoginResponseModel {
  LoginResponseModel({required this.token});

  final String token;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(token: json['token']?.toString() ?? '');
  }
}