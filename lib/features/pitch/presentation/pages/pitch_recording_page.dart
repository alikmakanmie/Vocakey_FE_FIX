import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:noise_meter/noise_meter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/pitch_bloc.dart';
import '../bloc/pitch_event.dart';
import '../bloc/pitch_state.dart';
import 'pitch_result_page.dart';

class PitchRecordingPage extends StatefulWidget {
  const PitchRecordingPage({Key? key}) : super(key: key);

  @override
  State<PitchRecordingPage> createState() => _PitchRecordingPageState();
}

class _PitchRecordingPageState extends State<PitchRecordingPage>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isAnalyzing = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;
  StreamSubscription? _blocSubscription;

  // ✅ Real-time audio amplitude
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  List<double> _amplitudes = List.filled(12, 0.2);
  double _currentDecibel = 0;

  @override
  void initState() {
    super.initState();
    _listenToBlocState();
    _noiseMeter = NoiseMeter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blocSubscription?.cancel();
    _noiseSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _listenToBlocState() {
    _blocSubscription = context.read<PitchBloc>().stream.listen((state) {
      if (!mounted) return;

      if (state is PitchAnalysisSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PitchResultPage(result: state.result),
          ),
        );
      } else if (state is PitchAnalysisError) {
        setState(() {
          _isAnalyzing = false;
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rekaman Gagal'),
            content: const Text(
              'Suara tidak terdeteksi. Pastikan Anda bersenandung dengan suara yang cukup keras.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startRecording();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDocumentsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        // Start audio recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        // ✅ Start listening to noise meter for real-time amplitude
        _startNoiseMonitoring();

        setState(() {
          _isRecording = true;
          _isAnalyzing = false;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          setState(() {
            _recordDuration++;
          });

          if (_recordDuration >= 10) {
            timer.cancel();
            _stopRecording();
          }
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  // ✅ Monitor microphone input in real-time
  void _startNoiseMonitoring() {
    try {
      _noiseSubscription = _noiseMeter?.noise.listen(
        (NoiseReading noiseReading) {
          if (!mounted) return;

          setState(() {
            _currentDecibel = noiseReading.meanDecibel;

            // Update amplitudes based on decibel level
            // Normalize decibel (typically 20-90 dB) to height (0.2-1.0)
            double normalizedDb = (_currentDecibel - 20).clamp(0, 70) / 70;
            
            // Shift existing values and add new one
            for (int i = _amplitudes.length - 1; i > 0; i--) {
              _amplitudes[i] = _amplitudes[i - 1];
            }
            _amplitudes[0] = 0.2 + (normalizedDb * 0.8);
          });
        },
        onError: (error) {
          print('Noise meter error: $error');
        },
      );
    } catch (e) {
      print('Error starting noise monitoring: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _noiseSubscription?.cancel(); // ✅ Stop noise monitoring
      
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _audioPath = path;
        _isAnalyzing = true;
        _amplitudes = List.filled(12, 0.2); // Reset amplitudes
      });

      if (path != null && mounted) {
        context.read<PitchBloc>().add(AnalyzeAudioEvent(path));
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isAnalyzing
                          ? null
                          : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Merekam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Title
              const Text(
                'Tentukan Suara Nada\nDasar Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 60),

              // Audio Spectrum (real-time sync)
              _isRecording
                  ? _AudioSpectrumVisualizer(
                      amplitudes: _amplitudes,
                      isRecording: _isRecording,
                    )
                  : const SizedBox(height: 150),

              const Spacer(),

              // Mic Button
              GestureDetector(
                onTap: !_isRecording && !_isAnalyzing ? _startRecording : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: _isAnalyzing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6B9FE8),
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          Icons.mic,
                          size: 60,
                          color: _isRecording
                              ? Colors.red
                              : const Color(0xFF6B9FE8),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Text
              Text(
                _isAnalyzing
                    ? 'Mohon tunggu sebentar...'
                    : (_isRecording
                        ? 'Mulai Rekaman Humming'
                        : 'Mulai Rekaman Humming'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isAnalyzing
                    ? ''
                    : 'Tahan tombol untuk merekam',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Real-time Audio Spectrum Visualizer
class _AudioSpectrumVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final bool isRecording;

  const _AudioSpectrumVisualizer({
    required this.amplitudes,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
          ),

          // Spectrum Bars (synced with mic input)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(12, (index) {
              // Use real amplitude data
              final amplitude = amplitudes[index];
              final height = 20 + (amplitude * 60); // 20-80px range

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          // Music note icon
          Positioned(
            top: 10,
            right: 30,
            child: Icon(
              Icons.music_note,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
