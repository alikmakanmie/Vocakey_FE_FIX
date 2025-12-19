import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/analysis_model.dart';

abstract class PitchRemoteDatasource {
  Future<AnalysisModel> analyzeAudio(String audioPath);
}

class PitchRemoteDatasourceImpl implements PitchRemoteDatasource {
  final ApiClient apiClient;

  PitchRemoteDatasourceImpl(this.apiClient);

  @override
  Future<AnalysisModel> analyzeAudio(String audioPath) async {
    try {
      print('📤 Uploading audio: $audioPath');
      
      final response = await apiClient.uploadAudio(
        ApiConstants.analyzeEndpoint,
        audioPath,
      );
      
      // ✅ DEBUG: Print response lengkap
      print('=== BACKEND RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('Response Type: ${response.data.runtimeType}');
      print('========================');
      
      if (response.statusCode == 200) {
        // Parse response
        final analysisResult = AnalysisModel.fromJson(response.data);
        
        print('✅ Parsed Result:');
        print('   Note: ${analysisResult.note}');
        print('   Range: ${analysisResult.vocalRange}');
        print('   Accuracy: ${analysisResult.accuracy}%');
        print('   Vocal Type: ${analysisResult.vocalType}');
        print('   Recommendations: ${analysisResult.recommendedSongs.length} songs');
        
        return analysisResult;
      } else {
        throw ServerException('Failed to analyze audio: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error in analyzeAudio: $e');
      throw ServerException(e.toString());
    }
  }
}
