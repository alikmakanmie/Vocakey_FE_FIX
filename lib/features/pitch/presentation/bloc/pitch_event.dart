import 'package:equatable/equatable.dart';

abstract class PitchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartRecordingEvent extends PitchEvent {}

class StopRecordingEvent extends PitchEvent {}

class AnalyzeAudioEvent extends PitchEvent {
  final String audioPath;
  
  AnalyzeAudioEvent(this.audioPath);
  
  @override
  List<Object?> get props => [audioPath];
}

class RetryRecordingEvent extends PitchEvent {}
