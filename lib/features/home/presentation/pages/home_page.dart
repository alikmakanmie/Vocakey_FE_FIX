import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../widgets/song_card.dart';
import '../../../song/presentation/pages/song_detail_page.dart';

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
      final response = await http.get(
        Uri.parse('https://pound-essex-clinical-thumbnails.trycloudflare.com/api/songs'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _songs = data['songs'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ Tambahkan ini agar gradient memenuhi seluruh layar
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: ResponsiveHelper.mediumSpacing,
            right: ResponsiveHelper.mediumSpacing,
            top: ResponsiveHelper.mediumSpacing,
            bottom: 100, // ✅ Space untuk bottom navigation bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  'VocaKey',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: ResponsiveHelper.fontSize(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.largeSpacing),

              // Riwayat Nada Dasar Title
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
                  String displayNote = 'D#';
                  String displaySubtext = 'C2 - A6 • 75.2%';

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

              // Daftar Lagu Section
              Text(
                'Daftar Lagu',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: ResponsiveHelper.fontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveHelper.mediumSpacing),

              // Horizontal Scrollable Song Cards
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SizedBox(
                      height: ResponsiveHelper.height(200),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: ResponsiveHelper.mediumSpacing,
                            ),
                            child: SongCard(
                              title: song['title'] ?? 'Unknown',
                              artist: song['artist'] ?? 'Unknown Artist',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/song-detail',
                                  arguments: SongDetailArguments(
                                    songTitle: song['title'] ?? 'Unknown',
                                    realArtist: song['artist'] ?? 'Unknown Artist',
                                    realOriginalKey: song['original_key'] ?? 'C major',
                                    realUserKey: 'C major',
                                    coverImageUrl: null,
                                    audioUrl: song['audio_url'],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
