part of 'step_bloc.dart';


abstract class StepState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StepInitial extends StepState {}

class StepLoading extends StepState {}

class PermissionsNotGranted extends StepState {}

class StepTrackingActive extends StepState {
  final int totalSteps;
  final StepSource source;
  final bool isHealthConnected;
  final List<StepRecord> records;

  StepTrackingActive({
    required this.totalSteps,
    required this.source,
    required this.isHealthConnected,
    required this.records,
  });

  @override
  List<Object?> get props => [totalSteps, source, isHealthConnected, records];

  StepTrackingActive copyWith({
    int? totalSteps,
    StepSource? source,
    bool? isHealthConnected,
    List<StepRecord>? records,
  }) {
    return StepTrackingActive(
      totalSteps: totalSteps ?? this.totalSteps,
      source: source ?? this.source,
      isHealthConnected: isHealthConnected ?? this.isHealthConnected,
      records: records ?? this.records,
    );
  }
}

class StepError extends StepState {
  final String message;
  StepError(this.message);

  @override
  List<Object?> get props => [message];
}