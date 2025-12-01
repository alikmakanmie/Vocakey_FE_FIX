import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';

import 'package:http/http.dart' as http;  // ✅ ADD THIS
import 'dart:convert';                     // ✅ ADD THIS

// ============================================================
// ARGUMENT DATA MODEL
// ============================================================

class SongDetailArguments {
  final String songTitle;
  final String realArtist;
  final String realOriginalKey;
  final String realUserKey;
  final String? coverImageUrl;
  final String? audioUrl;

  const SongDetailArguments({
    required this.songTitle,
    required this.realArtist,
    required this.realOriginalKey,
    required this.realUserKey,
    this.coverImageUrl,
    this.audioUrl,
  });
}

// ============================================================
// KEY CONSTANTS
// ============================================================

const Map<String, int> MAJOR_KEYS = {
  'C major': 0, 'C# major': 1, 'Db major': 1,
  'D major': 2, 'D# major': 3, 'Eb major': 3,
  'E major': 4, 'F major': 5, 'F# major': 6,
  'Gb major': 6, 'G major': 7, 'G# major': 8,
  'Ab major': 8, 'A major': 9, 'A# major': 10,
  'Bb major': 10, 'B major': 11,
};

const List<String> KEY_SEQUENCE = [
  'C major', 'C# major', 'D major', 'D# major', 'E major', 'F major',
  'F# major', 'G major', 'G# major', 'A major', 'A# major', 'B major',
];

// ============================================================
// SONG DETAIL PAGE
// ============================================================

class SongDetailPage extends StatefulWidget {
  final SongDetailArguments arguments;

  const SongDetailPage({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  int _currentTransposeSemitone = 0;
  
  // ✅ Audio Player
  late AudioPlayer _audioPlayer;
  bool _isPlayerInitialized = false;
  bool _isLoading = true;

  // ✅ ADD THESE
  bool _isTransposing = false;
  String? _transposedAudioUrl;
  int? _lastAppliedTranspose;
  
  // ✅ ADD THESE NEW VARIABLES
  String? _actualAudioUrl;  // ← ADD THIS
  bool _isFetchingSongData = true;  // ← ADD THIS
  
  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
void initState() {
  super.initState();
  _calculateInitialTranspose();
  _fetchSongDataFromBackend();  // ✅ CHANGED - Fetch data first
}

Future<void> _fetchSongDataFromBackend() async {
  try {
    final baseUrl = 'http://192.168.3.2:5000';
    
    // Use search endpoint to get song data + audio URL
    final encodedTitle = Uri.encodeComponent(widget.arguments.songTitle);
    
    print('🔍 Searching for song: ${widget.arguments.songTitle}');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/songs/search/$encodedTitle'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['song'] != null) {
        final song = data['song'];
        
        // Get audio URL from response
        String? audioUrl = song['audio_url'];
        
        if (audioUrl != null && audioUrl.isNotEmpty) {
          _actualAudioUrl = '$baseUrl$audioUrl';
          
          print('✅ Found audio URL: $_actualAudioUrl');
        }
      }
    } else {
      print('⚠️  Song not found: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Error fetching song data: $e');
  } finally {
    setState(() {
      _isFetchingSongData = false;
    });
    
    _initAudioPlayer();
  }
}


  Future<void> _initAudioPlayer() async {
  _audioPlayer = AudioPlayer();
  
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // ✅ Use fetched URL or construct simple URL (title only)
    String audioUrl;
    
    if (_actualAudioUrl != null && _actualAudioUrl!.isNotEmpty) {
      audioUrl = _actualAudioUrl!;
    } else {
      // Use title-only endpoint
      final baseUrl = 'http://192.168.3.2:5000';
      final safeTitle = widget.arguments.songTitle.replaceAll(' ', '_');
      audioUrl = '$baseUrl/songs/file/$safeTitle';
    }
    
    print('🎵 Loading audio from: $audioUrl');
    
    await _audioPlayer.setUrl(audioUrl);
    
    setState(() {
      _isPlayerInitialized = true;
      _isLoading = false;
    });
    
    print('✅ Audio player initialized');
    
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
    
  } catch (e) {
    print('❌ Error loading audio: $e');
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _calculateInitialTranspose() {
    final originalSemitone = _getSemitoneValue(widget.arguments.realOriginalKey);
    final userSemitone = _getSemitoneValue(widget.arguments.realUserKey);
    
    if (originalSemitone != null && userSemitone != null) {
      int difference = userSemitone - originalSemitone;
      if (difference > 6) difference -= 12;
      else if (difference < -6) difference += 12;
      _currentTransposeSemitone = difference;
    }
  }

  int? _getSemitoneValue(String keyName) => MAJOR_KEYS[keyName];

  String _getKeyNameFromSemitone(int semitone) {
    final normalizedSemitone = semitone % 12;
    final index = normalizedSemitone < 0 ? normalizedSemitone + 12 : normalizedSemitone;
    return (index >= 0 && index < KEY_SEQUENCE.length) ? KEY_SEQUENCE[index] : 'C major';
  }

  String get _targetKey {
    final userSemitone = _getSemitoneValue(widget.arguments.realUserKey);
    if (userSemitone == null) return widget.arguments.realUserKey;
    final targetSemitone = userSemitone + _currentTransposeSemitone;
    return _getKeyNameFromSemitone(targetSemitone);
  }

  bool get _isDirectMatch => _targetKey == widget.arguments.realUserKey;

  void _incrementTranspose() {
    if (_currentTransposeSemitone < 6) {
      setState(() => _currentTransposeSemitone++);
    }
  }

  void _decrementTranspose() {
    if (_currentTransposeSemitone > -6) {
      setState(() => _currentTransposeSemitone--);
    }
  }

  void _resetTranspose() async {
  _calculateInitialTranspose();
  
  // Reset to original audio if was transposed
  if (_transposedAudioUrl != null) {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _audioPlayer.pause();
      
      // Reload original audio
      final originalUrl = widget.arguments.audioUrl ?? 
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      
      await _audioPlayer.setUrl(originalUrl);
      
      setState(() {
        _transposedAudioUrl = null;
        _lastAppliedTranspose = null;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reset to original audio'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error resetting: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> _applyTranspose() async {
  if (_currentTransposeSemitone == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No transpose needed (0 semitone)'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  // Check if already applied
  if (_lastAppliedTranspose == _currentTransposeSemitone && _transposedAudioUrl != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transpose $_currentTransposeSemitone semitone already applied!'),
        backgroundColor: Colors.green,
      ),
    );
    return;
  }
  
  setState(() {
    _isTransposing = true;
  });
  
  try {
    // TODO: Get song_id from arguments
    // For now, we'll use title-based endpoint
    final songTitle = Uri.encodeComponent(widget.arguments.songTitle);
    final baseUrl = 'http://192.168.3.2:5000';
    
    print('🎵 Requesting transpose: $_currentTransposeSemitone semitones');
    
    // Call backend API to transpose
    final response = await http.post(
      Uri.parse('$baseUrl/api/songs/search/$songTitle/transpose'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'semitone_shift': _currentTransposeSemitone,
        'preserve_formant': true,
      }),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final transposedUrl = data['transposed_url'];
        
        print('✅ Transpose success: $transposedUrl');
        
        // Pause current audio
        await _audioPlayer.pause();
        
        // Load transposed audio
        await _audioPlayer.setUrl(transposedUrl);
        
        setState(() {
          _transposedAudioUrl = transposedUrl;
          _lastAppliedTranspose = _currentTransposeSemitone;
          _isTransposing = false;
        });
        
        // Auto play
        await _audioPlayer.play();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Transposed to ${data['new_key']} ($_currentTransposeSemitone semitones)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(data['error'] ?? 'Transpose failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Transpose error: $e');
    
    setState(() {
      _isTransposing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transpose failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}


  // ✅ Audio Player Controls
  Future<void> _togglePlayPause() async {
    if (!_isPlayerInitialized) return;
    
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C89F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C89F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Lagu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ SONG INFO CARD
              _buildSongInfoCard(),
              
              const SizedBox(height: 20),
              
              // ✅ AUDIO PLAYER CARD
              _buildAudioPlayerCard(),
              
              const SizedBox(height: 20),
              
              // ✅ TRANSPOSE SECTION
              _buildTransposeSection(),
              
              const SizedBox(height: 20),
              
              // ✅ ACTION BUTTONS
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Cover/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 32),
          ),
          
          const SizedBox(height: 12),
          
          // Song Title & Artist
          Text(
            widget.arguments.songTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          Text(
            widget.arguments.realArtist,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Key Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeyTag(
                'Nada Asli: ${widget.arguments.realOriginalKey}',
                Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 8),
              _buildKeyTag(
                'Nada Saya: ${widget.arguments.realUserKey}',
                const Color(0xFFFFB4D1),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Match Indicator
          if (_isDirectMatch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Cocok Langsung!',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E6F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Video Lagu Karaoke & Lirik',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // ✅ Play/Pause Button
          if (_isLoading)
            const CircularProgressIndicator()
          else if (!_isPlayerInitialized)
            const Text('Failed to load audio', style: TextStyle(color: Colors.red))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                    size: 48,
                    color: const Color(0xFF2D2D2D),
                  ),
                  onPressed: _togglePlayPause,
                ),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // ✅ Progress Bar
          if (_isPlayerInitialized)
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;
                
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF2D2D2D),
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        thumbColor: const Color(0xFF2D2D2D),
                        overlayColor: const Color(0xFF2D2D2D).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2D2D2D)),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2D2D2D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          
          // Fullscreen button placeholder
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Color(0xFF2D2D2D)),
              onPressed: () {
                // TODO: Implement fullscreen
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransposeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Transpose Nada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '${_currentTransposeSemitone >= 0 ? '+' : ''}$_currentTransposeSemitone Semitone',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Nada Target: $_targetKey',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Transpose Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Minus button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: _decrementTranspose,
                ),
              ),
              
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _currentTransposeSemitone.toDouble(),
                    min: -6,
                    max: 6,
                    divisions: 12,
                    onChanged: (value) {
                      setState(() => _currentTransposeSemitone = value.toInt());
                    },
                  ),
                ),
              ),
              
              // Plus button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _incrementTranspose,
                ),
              ),
            ],
          ),
          
          // Value labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-6', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                Text('0', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                Text('+6', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _isTransposing ? null : _resetTranspose,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            'Reset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      
      const SizedBox(width: 12),
      
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _isTransposing ? null : _applyTranspose,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isTransposing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, color: Color(0xFF9C89F5)),
          label: Text(
            _isTransposing ? 'Processing...' : 'Terapkan',
            style: const TextStyle(
              color: Color(0xFF9C89F5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildKeyTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
