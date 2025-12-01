import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/analysis_result.dart';
import 'song_detail_page.dart';

class PitchResultPage extends StatefulWidget {
  final AnalysisResult result;

  const PitchResultPage({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  State<PitchResultPage> createState() => _PitchResultPageState();
}

class _PitchResultPageState extends State<PitchResultPage> {
  @override
  void initState() {
    super.initState();
    print('=== PITCH RESULT PAGE ===');
    print('Note: ${widget.result.note}');
    print('Range: ${widget.result.vocalRange}');
    print('Accuracy: ${widget.result.accuracy}');
    print('Vocal Type: ${widget.result.vocalType}');
    print('Recommendations: ${widget.result.recommendedSongs?.length ?? 0}');
    print('=======================');
    _saveAnalysisResult();
  }

  Future<void> _saveAnalysisResult() async {
    try {
      await LocalStorageService.saveLastAnalysis(
        note: widget.result.note,
        vocalRange: widget.result.vocalRange,
        accuracy: widget.result.accuracy,
        vocalType: widget.result.vocalType,
      );
      await LocalStorageService.addToHistory(
        note: widget.result.note,
        vocalRange: widget.result.vocalRange,
        accuracy: widget.result.accuracy,
        vocalType: widget.result.vocalType,
      );
      print('✅ Analysis result saved to local storage');
    } catch (e) {
      print('❌ Error saving analysis result: $e');
    }
  }

  /// Navigate ke Song Detail Page
  void _navigateToSongDetail(String songTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongDetailPage(
          arguments: SongDetailArguments(
            songTitle: songTitle,
            realArtist: 'Various Artist',
            realOriginalKey: widget.result.note,
            realUserKey: widget.result.note,
            coverImageUrl: null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah recommendedSongs ada dan tidak kosong
    final hasRecommendations = widget.result.recommendedSongs != null &&
        widget.result.recommendedSongs!.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textWhite,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Hasil Nada Dasar',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: ResponsiveHelper.fontSize(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.xLargeSpacing),

                  // Music Note Icon
                  Icon(
                    Icons.music_note,
                    size: ResponsiveHelper.xLargeIcon * 2,
                    color: AppColors.textWhite,
                  ),
                  SizedBox(height: ResponsiveHelper.largeSpacing),

                  // Note Card
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.largeSpacing),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.radius(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Nada Dasar Anda Adalah :',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: ResponsiveHelper.fontSize(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.smallSpacing),
                        Text(
                          widget.result.note,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: ResponsiveHelper.fontSize(48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.largeSpacing),

                  // Vocal Info
                  Text(
                    'Rentang Vocal: ${widget.result.vocalRange}',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: ResponsiveHelper.fontSize(16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.smallSpacing),
                  Text(
                    'Akurasi: ${widget.result.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: ResponsiveHelper.fontSize(16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.result.vocalType != null &&
                      widget.result.vocalType!.isNotEmpty) ...[
                    SizedBox(height: ResponsiveHelper.smallSpacing),
                    Text(
                      'Tipe Vokal: ${widget.result.vocalType}',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: ResponsiveHelper.fontSize(16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  SizedBox(height: ResponsiveHelper.xLargeSpacing),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  hasRecommendations
                                      ? '${widget.result.recommendedSongs!.length} lagu cocok untuk Anda!'
                                      : 'Belum ada rekomendasi lagu',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardLight,
                            foregroundColor: AppColors.primaryBlue,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.mediumSpacing,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.radius(12),
                              ),
                            ),
                          ),
                          child: Text(
                            'Rekomendasi Lagu',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.fontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.mediumSpacing),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate ke Song Detail Page
                            if (hasRecommendations) {
                              final firstSong = widget.result.recommendedSongs![0];
                              _navigateToSongDetail(firstSong);
                            } else {
                              // Fallback
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SongDetailPage(
                                    arguments: SongDetailArguments(
                                      songTitle: 'Sample Song',
                                      realArtist: 'Sample Artist',
                                      realOriginalKey: widget.result.note,
                                      realUserKey: widget.result.note,
                                      coverImageUrl: null,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardLight,
                            foregroundColor: AppColors.primaryBlue,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.mediumSpacing,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.radius(12),
                              ),
                            ),
                          ),
                          child: Text(
                            'Transpose Lagu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.fontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: ResponsiveHelper.xLargeSpacing),

                  // ✅ RECOMMENDED SONGS LIST
                  if (hasRecommendations) ...[
                    // Section Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.queue_music,
                            color: AppColors.textWhite,
                            size: ResponsiveHelper.mediumIcon,
                          ),
                          SizedBox(width: ResponsiveHelper.smallSpacing),
                          Text(
                            'Lagu Rekomendasi (${widget.result.recommendedSongs!.length})',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: ResponsiveHelper.fontSize(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.mediumSpacing),

                    // Song List
                    ...widget.result.recommendedSongs!.map((song) {
                      return _buildSongCard(song);
                    }).toList(),
                  ] else ...[
                    // No recommendations message
                    Container(
                      padding: EdgeInsets.all(ResponsiveHelper.largeSpacing),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.radius(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_off,
                            color: AppColors.textWhite,
                            size: ResponsiveHelper.largeIcon,
                          ),
                          SizedBox(height: ResponsiveHelper.smallSpacing),
                          Text(
                            'Belum ada rekomendasi lagu',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: ResponsiveHelper.fontSize(16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: ResponsiveHelper.largeSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget untuk card lagu individual (String-based untuk sementara)
  Widget _buildSongCard(String songTitle) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.mediumSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.radius(12),
        ),
        border: Border.all(
          color: AppColors.textWhite.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSongDetail(songTitle),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.radius(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.mediumSpacing),
            child: Row(
              children: [
                // Song Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.radius(8),
                    ),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: AppColors.textWhite,
                    size: ResponsiveHelper.mediumIcon,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.mediumSpacing),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: ResponsiveHelper.fontSize(16),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveHelper.smallSpacing / 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.smallSpacing,
                              vertical: ResponsiveHelper.smallSpacing / 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.radius(4),
                              ),
                            ),
                            child: Text(
                              'Nada: ${widget.result.note}',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: ResponsiveHelper.fontSize(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textWhite,
                  size: ResponsiveHelper.mediumIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
