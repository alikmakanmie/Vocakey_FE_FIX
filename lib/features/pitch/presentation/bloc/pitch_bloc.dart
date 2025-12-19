import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/analyze_audio.dart';
import 'pitch_event.dart';
import 'pitch_state.dart';

class PitchBloc extends Bloc<PitchEvent, PitchState> {
  final AnalyzeAudio analyzeAudio;

  PitchBloc({required this.analyzeAudio}) : super(PitchInitial()) {
    on<AnalyzeAudioEvent>(_onAnalyzeAudio);
  }

  Future<void> _onAnalyzeAudio(
    AnalyzeAudioEvent event,
    Emitter<PitchState> emit,
  ) async {
    print('🔵 BLoC: Starting analysis...');
    print('   Audio path: ${event.audioPath}');

    // Progress 0%
    emit(PitchAnalyzing(progress: 0.0));
    print('📊 Progress: 0% - Memulai analisis...');
    await Future.delayed(const Duration(milliseconds: 800));

    // Progress 30%
    emit(PitchAnalyzing(progress: 0.3));
    print('📊 Progress: 30% - Mengunggah audio...');
    await Future.delayed(const Duration(milliseconds: 600));

    // Progress 60%
    emit(PitchAnalyzing(progress: 0.6));
    print('📊 Progress: 60% - Memproses pitch detection...');
    
    // Call API
    final result = await analyzeAudio(event.audioPath);

    // ✅ EXTRACT hasil DULU sebelum emit
    bool isSuccess = false;
    dynamic analysisResult;
    String? errorMessage;

    result.fold(
      (failure) {
        isSuccess = false;
        errorMessage = failure.message;
        print('❌ BLoC: Analysis failed - ${failure.message}');
      },
      (success) {
        isSuccess = true;
        analysisResult = success;
        print('✅ BLoC: Analysis success!');
        print('   Note: ${success.note}');
        print('   Range: ${success.vocalRange}');
        print('   Accuracy: ${success.accuracy}%');
        print('   Vocal Type: ${success.vocalType}');
      },
    );

    // ✅ EMIT berdasarkan hasil extraction
    if (isSuccess && analysisResult != null) {
      // Progress 90%
      emit(PitchAnalyzing(progress: 0.9));
      print('📊 Progress: 90% - Finalisasi hasil...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Success
      emit(PitchAnalysisSuccess(analysisResult));
      print('🟢 BLoC: State emitted - PitchAnalysisSuccess');
    } else {
      // Error
      emit(PitchAnalysisError(errorMessage ?? 'Unknown error'));
    }
  }
}
