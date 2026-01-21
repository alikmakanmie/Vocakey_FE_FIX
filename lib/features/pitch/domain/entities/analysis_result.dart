import 'package:equatable/equatable.dart';

/// Entity untuk hasil analisis vokal (Domain Layer)
/// 
/// Versi 2.0 - Simplified (sesuai backend baru):
/// - ❌ Hapus: vocalRange, accuracy, vocalType
/// - ✅ Keep: baseNote, songKey, recommendations
class AnalysisResult extends Equatable {
  /// Nada dasar dari humming (e.g., "G4", "C#5")
  final String baseNote;
  
  /// Frekuensi nada dasar dalam Hz (e.g., 392.00)
  final double baseFrequency;
  
  /// Key lagu yang terdeteksi (e.g., "G", "C#")
  final String songKey;
  
  /// Scale lagu (major/minor)
  final String songScale;
  
  /// Confidence score key detection (0.0 - 1.0)
  final double keyConfidence;
  
  /// List rekomendasi lagu dari YouTube Music
  final List<SongRecommendation> recommendations;

  const AnalysisResult({
    required this.baseNote,
    required this.baseFrequency,
    required this.songKey,
    required this.songScale,
    required this.keyConfidence,
    required this.recommendations,
  });

  /// Full key description (e.g., "G major", "C# minor")
  String get fullKey => '$songKey $songScale';

  /// Confidence dalam persentase (0-100%)
  double get confidencePercentage => keyConfidence * 100;

  @override
  List<Object?> get props => [
        baseNote,
        baseFrequency,
        songKey,
        songScale,
        keyConfidence,
        recommendations,
      ];

  @override
  String toString() {
    return 'AnalysisResult(baseNote: $baseNote, songKey: $fullKey, recommendations: ${recommendations.length} songs)';
  }
}

/// Entity untuk song recommendation
class SongRecommendation extends Equatable {
  final String title;
  final String artist;
  final String youtubeUrl;
  final String youtubeWatchUrl;
  final String duration;
  final String? thumbnail;
  final String? album;
  final double matchScore;

  const SongRecommendation({
    required this.title,
    required this.artist,
    required this.youtubeUrl,
    required this.youtubeWatchUrl,
    required this.duration,
    this.thumbnail,
    this.album,
    required this.matchScore,
  });

  factory SongRecommendation.fromJson(Map<String, dynamic> json) {
    return SongRecommendation(
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      youtubeWatchUrl: json['youtube_watch_url'] as String? ?? '',
      duration: json['duration'] as String? ?? 'Unknown',
      thumbnail: json['thumbnail'] as String?,
      album: json['album'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// ✅ ADDED: toJson method untuk serialization
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'youtube_url': youtubeUrl,
      'youtube_watch_url': youtubeWatchUrl,
      'duration': duration,
      'thumbnail': thumbnail,
      'album': album,
      'match_score': matchScore,
    };
  }

  /// Extract YouTube video ID
  String? get videoId {
    try {
      final uri = Uri.parse(youtubeWatchUrl);
      return uri.queryParameters['v'];
    } catch (e) {
      return null;
    }
  }

  /// Check if thumbnail available
  bool get hasThumbnail => thumbnail != null && thumbnail!.isNotEmpty;

  @override
  List<Object?> get props => [
        title,
        artist,
        youtubeUrl,
        youtubeWatchUrl,
        duration,
        thumbnail,
        album,
        matchScore,
      ];

  @override
  String toString() {
    return 'SongRecommendation(title: $title, artist: $artist, matchScore: ${matchScore.toStringAsFixed(1)})';
  }
}
