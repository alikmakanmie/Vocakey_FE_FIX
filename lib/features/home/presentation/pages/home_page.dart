import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../../../song/presentation/pages/song_detail_page.dart';
import '../../../music/presentation/pages/music_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    try {
      print('🔄 Fetching songs from API...');
      final response = await http.get(
        Uri.parse(
          'https://greene-broken-friendly-location.trycloudflare.com/api/songs?limit=30',
        ),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _songs = data['songs'] ?? [];
            _isLoading = false;
          });
          print('✅ Loaded ${_songs.length} songs');
        }
      }
    } catch (e) {
      print('❌ Error loading songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openYouTube(String url) async {
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(ResponsiveHelper.mediumSpacing),
              child: Text(
                'VocaKey',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: ResponsiveHelper.fontSize(28),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.mediumSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Riwayat Nada Dasar Section
                    Text(
                      'Riwayat Nada Dasar',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: ResponsiveHelper.fontSize(18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.mediumSpacing),

                    // BlocBuilder untuk display data
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        String displayNote = 'C2';
                        String displaySubtext = 'G# minor - 44.0%';

                        if (state is HomeAnalysisLoaded) {
                          displayNote = state.note;
                          if (state.vocalRange != 'Belum Dianalisis') {
                            displaySubtext =
                                '${state.vocalRange} • ${state.accuracy.toStringAsFixed(1)}%';
                          }
                        }

                        return Container(
                          width: double.infinity,
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
                                displaySubtext,
                                style: TextStyle(
                                  color: AppColors.textDark.withOpacity(0.7),
                                  fontSize: ResponsiveHelper.fontSize(14),
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.smallSpacing),
                              Text(
                                displayNote,
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: ResponsiveHelper.fontSize(36),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: ResponsiveHelper.xLargeSpacing),

                    // Daftar Lagu Section Title
                    Text(
                      'Daftar Lagu Popular',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: ResponsiveHelper.fontSize(18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.mediumSpacing),

                    // ✅ VERTICAL LIST dengan THUMBNAIL
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          )
                        : _songs.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No songs available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _songs.length,
                                itemBuilder: (context, index) {
                                  final song = _songs[index];
                                  return _buildSongCard(song);
                                },
                              ),

                    SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Vertical Song Card dengan Thumbnail
  Widget _buildSongCard(Map<String, dynamic> song) {
  final title = song['title'] ?? 'Unknown';
  final artist = song['artist'] ?? 'Unknown Artist';
  final duration = song['duration'] ?? 'Unknown';
  final thumbnail = song['thumbnail'];
  final videoId = song['video_id'] ?? '';

  return Container(
    margin: EdgeInsets.only(bottom: ResponsiveHelper.mediumSpacing),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // ✅ Navigate to Music Player Page
          if (videoId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayerPage(
                  videoId: videoId,
                  title: title,
                  artist: artist,
                  thumbnail: thumbnail,
                  duration: duration,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail != null && thumbnail.isNotEmpty
                    ? Image.network(
                        thumbnail,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      artist,
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
                          duration,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play Icon
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF6B9FE8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}
