import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../bloc/song_bloc.dart';
import '../bloc/song_event.dart';
import '../bloc/song_state.dart';
import '../widgets/transpose_slider.dart';
import '../widgets/video_player_widget.dart';

class SongDetailPage extends StatefulWidget {
  final String songId;

  const SongDetailPage({
    Key? key,
    required this.songId,
  }) : super(key: key);

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SongBloc>().add(LoadSongDetailEvent(widget.songId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: BlocBuilder<SongBloc, SongState>(
            builder: (context, state) {
              if (state is SongLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textWhite,
                  ),
                );
              }

              if (state is SongError) {
                return Center(
                  child: Text(
                    state.message,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: ResponsiveHelper.fontSize(16),
                    ),
                  ),
                );
              }

              if (state is SongDetailLoaded) {
                final song = state.songDetail;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.all(ResponsiveHelper.mediumSpacing),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.textWhite,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              AppStrings.detailSongTitle,
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: ResponsiveHelper.fontSize(20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Album Cover
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.mediumSpacing,
                        ),
                        child: Container(
                          width: ResponsiveHelper.width(120),
                          height: ResponsiveHelper.width(120),
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.radius(15),
                            ),
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: ResponsiveHelper.xLargeIcon,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.mediumSpacing),

                      // Song Title
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.mediumSpacing,
                        ),
                        child: Text(
                          song.title,
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: ResponsiveHelper.fontSize(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.mediumSpacing),

                      // Note Chips
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.mediumSpacing,
                        ),
                        child: Row(
                          children: [
                            _buildNoteChip(
                              '${AppStrings.originalNote} ${song.originalNote}',
                              false,
                            ),
                            SizedBox(width: ResponsiveHelper.smallSpacing),
                            _buildNoteChip(
                              '${AppStrings.yourNote} ${song.userNote ?? "G Mayor"}',
                              false,
                            ),
                            SizedBox(width: ResponsiveHelper.smallSpacing),
                            if (song.isDirectMatch)
                              _buildNoteChip(
                                AppStrings.matchDirect,
                                true,
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.largeSpacing),

                      // Video Player
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.mediumSpacing,
                        ),
                        child: VideoPlayerWidget(
                          videoUrl: song.videoUrl,
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.largeSpacing),

                      // Transpose Section
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.mediumSpacing,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.transposeNote,
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: ResponsiveHelper.fontSize(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.mediumSpacing),
                            TransposeSlider(
                              initialValue: song.transposeSemitone,
                              onChanged: (value) {
                                context.read<SongBloc>().add(
                                  TransposeSongEvent(value.toInt()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.xLargeSpacing),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoteChip(String label, bool isMatch) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.mediumSpacing,
        vertical: ResponsiveHelper.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: isMatch ? Colors.green : AppColors.textWhite,
        borderRadius: BorderRadius.circular(ResponsiveHelper.radius(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatch)
            Icon(
              Icons.check_circle,
              size: ResponsiveHelper.fontSize(14),
              color: AppColors.textWhite,
            ),
          if (isMatch) SizedBox(width: ResponsiveHelper.smallSpacing / 2),
          Text(
            label,
            style: TextStyle(
              color: isMatch ? AppColors.textWhite : AppColors.textDark,
              fontSize: ResponsiveHelper.fontSize(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
