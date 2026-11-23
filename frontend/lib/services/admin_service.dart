// The admin's account endpoints (/api/users). Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/user.dart';

class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  /// Accounts filtered by [status] (pending, approved, rejected; a comma
  /// list is allowed) and/or [role]. Admins are never included.
  Future<List<AppUser>> users({String? status, String? role}) async {
    final data = (await _api.get('/users', query: {'status': status, 'role': role})).data;
    return [for (final u in data['users'] as List) AppUser.fromJson(u as Map<String, dynamic>)];
  }

  /// Approve or reject an account. Returns the updated account and the
  /// server's message for the slip.
  Future<(AppUser, String)> verify(String id, {required bool approve}) async {
    final res = await _api.patch('/users/$id/verify', body: {'status': approve ? 'approved' : 'rejected'});
    return (AppUser.fromJson(res.data['user'] as Map<String, dynamic>), res.message);
  }
}
