import '../../domain/entities/analysis_result.dart';

class AnalysisModel extends AnalysisResult {
  const AnalysisModel({
    required String note,
    required String vocalRange,
    required double accuracy,
    String? vocalType,
    List<String> recommendedSongs = const [], // ✅ Default empty list
  }) : super(
          note: note,
          vocalRange: vocalRange,
          accuracy: accuracy,
          vocalType: vocalType,
          recommendedSongs: recommendedSongs,
        );

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    print('=== PARSING ANALYSIS RESULT ===');
    print('Raw JSON: $json');
    
    // Parse recommended_songs dari recommendations array
    List<String> songs = []; // ✅ Default empty list, not nullable
    
    if (json['recommended_songs'] != null) {
      // ✅ Jika ada field recommended_songs (list of strings)
      print('Found recommended_songs field');
      try {
        songs = List<String>.from(json['recommended_songs']);
      } catch (e) {
        print('Error parsing recommended_songs: $e');
      }
    } else if (json['recommendations'] != null) {
      // ✅ Jika tidak ada, extract dari recommendations array
      print('Extracting from recommendations array');
      try {
        final recs = json['recommendations'] as List;
        songs = recs.map((song) {
          if (song is Map<String, dynamic>) {
            return song['title'] as String? ?? 'Unknown Song';
          } else if (song is String) {
            return song;
          }
          return 'Unknown Song';
        }).toList();
        print('Extracted ${songs.length} songs: $songs');
      } catch (e) {
        print('Error extracting recommendations: $e');
      }
    }

    // Parse note from nested data object
    final String note = json['data']?['note'] ?? json['note'] ?? 'Unknown';
    final String vocalRange = json['data']?['vocal_range'] ?? json['vocal_range'] ?? 'Unknown';
    final double accuracy = (json['data']?['accuracy'] ?? json['accuracy'] ?? 0.0).toDouble();
    final String? vocalType = json['data']?['vocal_type'] ?? json['vocal_type'];

    print('Parsed data:');
    print('  - Note: $note');
    print('  - Vocal Range: $vocalRange');
    print('  - Accuracy: $accuracy');
    print('  - Vocal Type: $vocalType');
    print('  - Recommended Songs: ${songs.length}');
    print('===============================');

    return AnalysisModel(
      note: note,
      vocalRange: vocalRange,
      accuracy: accuracy,
      vocalType: vocalType,
      recommendedSongs: songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'vocal_range': vocalRange,
      'accuracy': accuracy,
      'vocal_type': vocalType,
      'recommended_songs': recommendedSongs,
    };
  }

  @override
  String toString() {
    return 'AnalysisModel(note: $note, vocalRange: $vocalRange, accuracy: $accuracy, vocalType: $vocalType, recommendedSongs: ${recommendedSongs.length})';
  }
}
