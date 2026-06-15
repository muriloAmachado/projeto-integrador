import '../../../../core/network/api_client.dart';
import '../models/login_response_model.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/users/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    return LoginResponseModel.fromJson(response);
  }
}