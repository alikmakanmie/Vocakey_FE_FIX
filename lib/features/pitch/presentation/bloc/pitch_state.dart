import 'package:equatable/equatable.dart';
import '../../domain/entities/analysis_result.dart';

abstract class PitchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PitchInitial extends PitchState {}

class PitchRecording extends PitchState {
  final int duration;
  
  PitchRecording(this.duration);
  
  @override
  List<Object?> get props => [duration];
}

class PitchRecordingComplete extends PitchState {
  final String audioPath;
  
  PitchRecordingComplete(this.audioPath);
  
  @override
  List<Object?> get props => [audioPath];
}

class PitchAnalyzing extends PitchState {}

class PitchAnalysisSuccess extends PitchState {
  final AnalysisResult result;
  
  PitchAnalysisSuccess(this.result);
  
  @override
  List<Object?> get props => [result];
}

class PitchAnalysisError extends PitchState {
  final String message;
  
  PitchAnalysisError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class PitchPermissionDenied extends PitchState {}
