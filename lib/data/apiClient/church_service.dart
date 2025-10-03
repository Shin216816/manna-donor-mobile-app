import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/church.dart';
import 'package:manna_donate_app/core/api_service.dart';

class ChurchService {
  final ApiService _api = ApiService();

  /// Search for churches
  Future<ApiResponse<List<Church>>> searchChurches(String query) async {
    try {
      final response = await _api.get(
        '/mobile/church/search',
        queryParameters: {'q': query},
      );
      return ApiResponse.fromJson(response.data, (data) {
        // Handle the nested structure: data.churches
        if (data is Map<String, dynamic> && data.containsKey('churches')) {
          final churchesList = data['churches'] as List;
          return churchesList.map((json) => Church.fromJson(json)).toList();
        }
        // Fallback for direct list structure
        if (data is List) {
          return data.map((json) => Church.fromJson(json)).toList();
        }
        return [];
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to search churches: $e',
      );
    }
  }

  /// Get all available churches
  Future<ApiResponse<List<Church>>> getAllChurches() async {
    try {
      final response = await _api.get(
        '/mobile/church/search',
        queryParameters: {'q': 'all'},
      );
      
      return ApiResponse.fromJson(response.data, (data) {
        // Handle the nested structure: data.churches
        if (data is Map<String, dynamic> && data.containsKey('churches')) {
          final churchesList = data['churches'] as List;
          return churchesList.map((json) {
            try {
              return Church.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              // Log parsing error but continue with other churches
              return null;
            }
          }).where((church) => church != null).cast<Church>().toList();
        }
        // Fallback for direct list structure
        if (data is List) {
          return data.map((json) {
            try {
              return Church.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              // Log parsing error but continue with other churches
              return null;
            }
          }).where((church) => church != null).cast<Church>().toList();
        }
        return <Church>[];
      });
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to get churches: $e');
    }
  }

  /// Get available churches (alias for getAllChurches)
  Future<ApiResponse<List<Church>>> getAvailableChurches() async {
    return getAllChurches();
  }

  /// Get church by ID
  Future<ApiResponse<Church>> getChurchById(String churchId) async {
    try {
      final response = await _api.get('/mobile/church/$churchId');
      return ApiResponse.fromJson(
        response.data,
        (data) => Church.fromJson(data),
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to get church: $e');
    }
  }

  /// Associate user with church
  Future<ApiResponse<Map<String, dynamic>>> associateWithChurch(
    String userId,
    String churchId,
  ) async {
    try {
      final response = await _api.put(
        '/mobile/auth/church/$userId?church_id=$churchId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to associate with church: $e',
      );
    }
  }

  /// Select church for user
  Future<ApiResponse<Map<String, dynamic>>> selectChurch(
    String userId,
    String churchId,
  ) async {
    try {
      final response = await _api.post('/mobile/church/$churchId/select');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to select church: $e',
      );
    }
  }

  /// Get user's associated churches
  Future<ApiResponse<List<Church>>> getUserChurches(String userId) async {
    try {
      final response = await _api.get('/mobile/auth/church/$userId');
      return ApiResponse.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((json) => Church.fromJson(json)).toList();
        }
        return [];
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get user churches: $e',
      );
    }
  }

  /// Get user's church information
  Future<ApiResponse<Map<String, dynamic>>> getUserChurchInfo(
    String userId,
  ) async {
    try {
      final response = await _api.get('/mobile/church/user/me');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get user church info: $e',
      );
    }
  }

  /// Unselect church for user
  Future<ApiResponse<Map<String, dynamic>>> unselectChurch(
    String userId,
  ) async {
    try {
      final response = await _api.delete('/mobile/church/user/me');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to unselect church: $e',
      );
    }
  }
}
