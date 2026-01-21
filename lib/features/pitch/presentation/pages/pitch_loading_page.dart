import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/pitch_bloc.dart';
import '../bloc/pitch_state.dart';
import 'pitch_result_page.dart';

class PitchLoadingPage extends StatelessWidget {
  const PitchLoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PitchBloc, PitchState>(
      listener: (context, state) {
        // Navigate on success
        if (state is PitchAnalysisSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PitchResultPage(result: state.result),
            ),
          );
        }
        // Show error dialog
        else if (state is PitchAnalysisError) {
          _showErrorDialog(context, state.message);
        }
      },
      builder: (context, state) {
        // Extract progress from state
        double currentProgress = 0.0;
        String statusMessage = 'Initializing...';

        if (state is PitchAnalyzing) {
          currentProgress = state.progress;
          statusMessage = state.statusMessage;
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ✅ CIRCULAR PROGRESS with Percentage
                      CircularPercentIndicator(
                        radius: 100.0,
                        lineWidth: 12.0,
                        percent: currentProgress.clamp(0.0, 1.0),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Icon(
                              _getProgressIcon(currentProgress),
                              size: 50,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            // Percentage
                            Text(
                              '${(currentProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animateFromLastPercent: true,
                      ),

                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'Analyzing Your Voice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Status Message (dynamic from backend/state)
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✅ LINEAR PROGRESS BAR (Secondary indicator)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Progress steps
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ProgressStep(
                                  icon: Icons.upload_file,
                                  label: 'Upload',
                                  isActive: currentProgress >= 0.0,
                                  isCompleted: currentProgress > 0.33,
                                ),
                                _ProgressStep(
                                  icon: Icons.music_note,
                                  label: 'Detect',
                                  isActive: currentProgress >= 0.33,
                                  isCompleted: currentProgress > 0.66,
                                ),
                                _ProgressStep(
                                  icon: Icons.check_circle,
                                  label: 'Finalize',
                                  isActive: currentProgress >= 0.66,
                                  isCompleted: currentProgress >= 1.0,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Linear progress
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: currentProgress,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Loading animation dots
                      const _LoadingDots(),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getProgressIcon(double progress) {
    if (progress < 0.33) {
      return Icons.cloud_upload_outlined;
    } else if (progress < 0.66) {
      return Icons.settings_voice;
    } else if (progress < 1.0) {
      return Icons.analytics_outlined;
    } else {
      return Icons.check_circle_outline;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Analysis Failed', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          message.isEmpty
              ? 'Voice not detected. Please hum or sing clearly.'
              : message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Back to recording page
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// ✅ Progress Step Widget
class _ProgressStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.white
                : (isActive
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1)),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted
                ? const Color(0xFF6B9FE8)
                : (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ✅ Loading Dots Animation
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity.clamp(0.3, 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(opacity.clamp(0.1, 0.5)),
                    blurRadius: 6,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
