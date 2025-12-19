import 'package:equatable/equatable.dart';

class AnalysisResult extends Equatable {
  final String note;
  final String vocalRange;
  final double accuracy;
  final List<String> recommendedSongs;
  final String? vocalType;  // ✅ Tambahkan property ini

  const AnalysisResult({
    required this.note,
    required this.vocalRange,
    required this.accuracy,
    required this.recommendedSongs,
    this.vocalType,  // ✅ Tambahkan parameter ini
  });

  @override
  List<Object?> get props => [
    note,
    vocalRange,
    accuracy,
    recommendedSongs,
    vocalType,  // ✅ Tambahkan di props
  ];
}
