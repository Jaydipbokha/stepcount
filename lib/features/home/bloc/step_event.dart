part of 'step_bloc.dart';

abstract class StepEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeStepTracking extends StepEvent {}

class RequestPermissions extends StepEvent {}

class StartStepTracking extends StepEvent {}

class StepCountUpdated extends StepEvent {
  final int stepCount;
  StepCountUpdated(this.stepCount);

  @override
  List<Object?> get props => [stepCount];
}

class SourceUpdated extends StepEvent {
  final StepSource source;
  SourceUpdated(this.source);

  @override
  List<Object?> get props => [source];
}

class ConnectToHealth extends StepEvent {}

class DisconnectFromHealth extends StepEvent {}

class RefreshStepRecords extends StepEvent {}

class UpdateStepCount extends StepEvent {
  final int steps;

  const UpdateStepCount(this.steps);

  @override
  List<Object> get props => [steps];
}

class UpdateStepSource extends StepEvent {
  final StepSource source;

  const UpdateStepSource(this.source);

  @override
  List<Object> get props => [source];
}

class UpdateStepRecords extends StepEvent {
  final List<StepRecord> records;

  const UpdateStepRecords(this.records);

  @override
  List<Object> get props => [records];
}