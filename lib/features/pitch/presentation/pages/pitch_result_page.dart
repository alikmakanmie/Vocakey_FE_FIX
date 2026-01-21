import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/analysis_result.dart';

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
  YoutubePlayerController? _youtubeController;
  int _selectedSongIndex = 0;

  @override
  void initState() {
    super.initState();
    _printResultToConsole();
    _saveAnalysisResult();
    _initializeYoutubePlayer();
  }

  void _printResultToConsole() {
    print('\n' + '=' * 60);
    print('🎵 PITCH ANALYSIS RESULT (v2.0)');
    print('=' * 60);
    print('📌 Base Note      : ${widget.result.baseNote}');
    print('📊 Base Frequency : ${widget.result.baseFrequency} Hz');
    print('🎹 Song Key       : ${widget.result.fullKey}');
    print('🎯 Confidence     : ${widget.result.confidencePercentage.toStringAsFixed(1)}%');
    print('🎼 Recommendations: ${widget.result.recommendations.length} songs');

    if (widget.result.recommendations.isNotEmpty) {
      print('\n📀 Recommended Songs:');
      for (int i = 0; i < widget.result.recommendations.length; i++) {
        final song = widget.result.recommendations[i];
        print('  ${i + 1}. ${song.title} - ${song.artist} (Score: ${song.matchScore.toStringAsFixed(1)})');
      }
    }
    print('=' * 60 + '\n');
  }

  Future<void> _saveAnalysisResult() async {
    try {
      await LocalStorageService.saveLastAnalysis(
        note: widget.result.baseNote,
        vocalRange: widget.result.fullKey, // Save key instead
        accuracy: widget.result.confidencePercentage,
        vocalType: null,
      );
      print('✅ Analysis result saved to local storage');
    } catch (e) {
      print('❌ Error saving analysis result: $e');
    }
  }

  void _initializeYoutubePlayer() {
    if (widget.result.recommendations.isNotEmpty) {
      final firstSong = widget.result.recommendations[0];
      final videoId = firstSong.videoId;

      if (videoId != null && videoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
          ),
        );
      }
    }
  }

  void _changeSong(int index) {
    final song = widget.result.recommendations[index];
    final videoId = song.videoId;

    if (videoId != null && videoId.isNotEmpty) {
      setState(() {
        _selectedSongIndex = index;
        _youtubeController?.load(videoId);
      });
    }
  }

  Future<void> _openInYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open YouTube')),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRecommendations = widget.result.recommendations.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ✅ HEADER
              _buildHeader(),

              // ✅ SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ✅ RESULT CARD (Base Note + Key)
                      _buildResultCard(),

                      const SizedBox(height: 24),

                      // ✅ YOUTUBE VIDEO PLAYER (if available)
                      if (hasRecommendations && _youtubeController != null)
                        _buildVideoPlayer(),

                      const SizedBox(height: 16),

                      // ✅ SONG RECOMMENDATIONS LIST
                      if (hasRecommendations)
                        _buildRecommendationsList()
                      else
                        _buildNoRecommendations(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Analysis Result',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B9FE8).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 48,
              color: Color(0xFF6B9FE8),
            ),
          ),

          const SizedBox(height: 20),

          // Base Note
          const Text(
            'Your Base Note',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.result.baseNote,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            '${widget.result.baseFrequency.toStringAsFixed(2)} Hz',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            color: Colors.black12,
          ),

          const SizedBox(height: 24),

          // Song Key Detection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.piano,
                label: 'Song Key',
                value: widget.result.fullKey,
              ),
              _buildInfoChip(
                icon: Icons.bar_chart,
                label: 'Confidence',
                value: '${widget.result.confidencePercentage.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6B9FE8), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF6B9FE8),
          bottomActions: [
            CurrentPosition(),
            ProgressBar(
              isExpanded: true,
              colors: const ProgressBarColors(
                playedColor: Color(0xFF6B9FE8),
                handleColor: Color(0xFF6B9FE8),
              ),
            ),
            RemainingDuration(),
            FullScreenButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.queue_music_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recommended Songs (${widget.result.recommendations.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: widget.result.recommendations.length,
          itemBuilder: (context, index) {
            final song = widget.result.recommendations[index];
            final isSelected = index == _selectedSongIndex;
            return _buildSongCard(song, index, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildSongCard(SongRecommendation song, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6B9FE8).withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6B9FE8)
              : Colors.white.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changeSong(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.hasThumbnail
                      ? Image.network(
                          song.thumbnail!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 12),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            song.duration,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.stars,
                            size: 14,
                            color: Colors.yellow.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            song.matchScore.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Play Icon & Open YouTube
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isSelected ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => _changeSong(index),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => _openInYouTube(song.youtubeWatchUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF6B9FE8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildNoRecommendations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.music_off,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recommendations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try recording again with a clearer voice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
