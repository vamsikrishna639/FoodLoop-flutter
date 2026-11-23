// Talks to the /api/auth endpoints. Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/user.dart';

/// A logged-in session: the token plus the account it belongs to.
class AuthSession {
  const AuthSession(this.token, this.user);
  final String token;
  final AppUser user;
}

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<AuthSession> login(String email, String password) async {
    final res = await _api.post('/auth/login', body: {'email': email, 'password': password});
    return _session(res.data);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    String organization = '',
  }) async {
    final res = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role.apiValue,
      'phone': phone,
      'organization': organization,
    });
    return _session(res.data);
  }

  /// Loads the account for the token already set on the client.
  Future<AppUser> me() async {
    final res = await _api.get('/auth/me');
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  AuthSession _session(dynamic data) => AuthSession(
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
}
