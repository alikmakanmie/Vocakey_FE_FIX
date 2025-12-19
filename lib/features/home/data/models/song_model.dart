import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.originalNote,
    super.albumCover,
    super.isMatchWithUserNote,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['judul'] ?? '',
      artist: json['artist'] ?? json['artis'] ?? '',
      originalNote: json['original_note'] ?? json['nada_asli'] ?? '',
      albumCover: json['album_cover'] ?? json['cover'],
      isMatchWithUserNote: json['is_match'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'original_note': originalNote,
      'album_cover': albumCover,
      'is_match': isMatchWithUserNote,
    };
  }
}
