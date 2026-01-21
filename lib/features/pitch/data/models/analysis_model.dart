import '../../domain/entities/analysis_result.dart';

/// Model untuk response API analisis vokal
/// Sesuai dengan backend response format baru (v2.0)
class AnalysisModel extends AnalysisResult {
  const AnalysisModel({
    required String baseNote,
    required double baseFrequency,
    required String songKey,
    required String songScale,
    required double keyConfidence,
    required List<SongRecommendation> recommendations,
  }) : super(
          baseNote: baseNote,
          baseFrequency: baseFrequency,
          songKey: songKey,
          songScale: songScale,
          keyConfidence: keyConfidence,
          recommendations: recommendations,
        );

  /// Parse dari JSON response backend
  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    print('=== PARSING ANALYSIS RESULT (v2.0) ===');

    // Parse data object
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final songKeyData = data['song_key'] as Map<String, dynamic>? ?? {};

    // Extract base note & frequency
    final String baseNote = data['base_note'] as String? ?? 'Unknown';
    final double baseFrequency = 
        (data['base_frequency'] as num?)?.toDouble() ?? 0.0;

    // Extract song key info
    final String songKey = songKeyData['key'] as String? ?? 'Unknown';
    final String songScale = songKeyData['scale'] as String? ?? 'major';
    final double keyConfidence = 
        (songKeyData['confidence'] as num?)?.toDouble() ?? 0.0;

    // Parse recommendations
    List<SongRecommendation> recommendations = [];
    if (json['recommendations'] != null) {
      try {
        final recs = json['recommendations'] as List;
        recommendations = recs.map((song) {
          return SongRecommendation.fromJson(song as Map<String, dynamic>);
        }).toList();
        
        print('✓ Parsed ${recommendations.length} recommendations');
      } catch (e) {
        print('❌ Error parsing recommendations: $e');
      }
    }

    print('Parsed data:');
    print(' - Base Note: $baseNote');
    print(' - Base Frequency: $baseFrequency Hz');
    print(' - Song Key: $songKey $songScale');
    print(' - Key Confidence: ${(keyConfidence * 100).toStringAsFixed(1)}%');
    print(' - Recommendations: ${recommendations.length} songs');
    print('=====================================');

    return AnalysisModel(
      baseNote: baseNote,
      baseFrequency: baseFrequency,
      songKey: songKey,
      songScale: songScale,
      keyConfidence: keyConfidence,
      recommendations: recommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'base_note': baseNote,
        'base_frequency': baseFrequency,
        'song_key': {
          'key': songKey,
          'scale': songScale,
          'confidence': keyConfidence,
          'full_key': '$songKey $songScale',
        },
      },
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'AnalysisModel(baseNote: $baseNote, songKey: $songKey $songScale, recommendations: ${recommendations.length})';
  }
}
