import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/pitch_bloc.dart';
import '../bloc/pitch_state.dart';
import 'pitch_result_page.dart';

class PitchLoadingPage extends StatelessWidget {
  const PitchLoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🟢 Loading Page: Built');
    
    return BlocBuilder<PitchBloc, PitchState>(
      builder: (context, state) {
        print('🟡 Loading Page: BlocBuilder state = ${state.runtimeType}');
        
        // ✅ Check state and navigate
        if (state is PitchAnalysisSuccess) {
          print('✅ Loading Page: Success detected! Scheduling navigation...');
          
          // Use WidgetsBinding to schedule navigation after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🚀 Executing navigation to result page...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PitchResultPage(result: state.result),
              ),
            );
          });
        } else if (state is PitchAnalysisError) {
          print('❌ Loading Page: Error detected! Scheduling dialog...');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Rekaman Gagal'),
                content: Text(
                  'Suara tidak terdeteksi. Pastikan Anda bersenandung dengan suara yang cukup keras.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          });
        }
        
        // ✅ Always show loading UI while waiting
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: ResponsiveHelper.width(150),
                      height: ResponsiveHelper.height(150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: ResponsiveHelper.width(100),
                          height: ResponsiveHelper.height(100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.xLargeSpacing),
                    Text(
                      'Menganalisis Suara Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.smallSpacing),
                    Text(
                      'Mohon tunggu sebentar...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: ResponsiveHelper.fontSize(14),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.xLargeSpacing),
                    _LoadingDots(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity.clamp(0.3, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
