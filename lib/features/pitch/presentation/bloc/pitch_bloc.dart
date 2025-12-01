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
    print('🔵 BLoC: Starting analysis...'); // ✅ Debug log
    print('   Audio path: ${event.audioPath}');
    
    // ✅ Hapus emit loading jika state tidak ada
    // emit(PitchAnalysisLoading());

    final result = await analyzeAudio(event.audioPath);

    result.fold(
      (failure) {
        print('❌ BLoC: Analysis failed - ${failure.message}'); // ✅ Debug log
        emit(PitchAnalysisError(failure.message));
      },
      (analysisResult) {
        print('✅ BLoC: Analysis success!'); // ✅ Debug log
        print('   Note: ${analysisResult.note}');
        print('   Range: ${analysisResult.vocalRange}');
        print('   Accuracy: ${analysisResult.accuracy}%');
        print('   Vocal Type: ${analysisResult.vocalType}');
        
        emit(PitchAnalysisSuccess(analysisResult)); // ✅ Emit success
        
        print('🟢 BLoC: State emitted - PitchAnalysisSuccess');
      },
    );
  }
}
