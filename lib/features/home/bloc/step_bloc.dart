import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stepcount/services/step_service.dart';

import '../../../models/step_record.dart';
import '../../../models/step_source.dart';

part 'step_event.dart';
part 'step_state.dart';

/*
class StepBloc extends Bloc<StepEvent, StepState> {
  final StepService _stepService;
  StreamSubscription? _stepCountSubscription;
  StreamSubscription? _sourceSubscription;

  StepBloc(this._stepService) : super(StepInitial()) {
    on<InitializeStepTracking>(_onInitialize);
    on<RequestPermissions>(_onRequestPermissions);
    on<StartStepTracking>(_onStartTracking);
    on<StepCountUpdated>(_onStepCountUpdated);
    on<SourceUpdated>(_onSourceUpdated);
    on<ConnectToHealth>(_onConnectToHealth);
    on<DisconnectFromHealth>(_onDisconnectFromHealth);
    on<RefreshStepRecords>(_onRefreshStepRecords);
  }

  Future<void> _onInitialize(
      InitializeStepTracking event,
      Emitter<StepState> emit,
      ) async {
    emit(StepLoading());
    try {
      await _stepService.initialize();
      add(RequestPermissions());
    } catch (e) {
      emit(StepError('Initialization failed: $e'));
    }
  }

  Future<void> _onRequestPermissions(
      RequestPermissions event,
      Emitter<StepState> emit,
      ) async {
    final granted = await _stepService.requestPermissions();

    if (granted) {
      add(StartStepTracking());
    } else {
      emit(PermissionsNotGranted());
    }
  }

  Future<void> _onStartTracking(
      StartStepTracking event,
      Emitter<StepState> emit,
      ) async {
    try {
      await _stepService.startTracking();

      // Subscribe to step count updates
      _stepCountSubscription = _stepService.stepCountStream.listen((stepCount) {
        add(StepCountUpdated(stepCount));
      });

      // Subscribe to source updates
      _sourceSubscription = _stepService.sourceStream.listen((source) {
        add(SourceUpdated(source));
      });

      emit(StepTrackingActive(
        totalSteps: _stepService.totalSteps,
        source: _stepService.currentSource,
        isHealthConnected: _stepService.isHealthConnected,
        records: _stepService.getStepRecords(),
      ));
    } catch (e) {
      emit(StepError('Failed to start tracking: $e'));
    }
  }

  void _onStepCountUpdated(
      StepCountUpdated event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(
        totalSteps: event.stepCount,
        records: _stepService.getStepRecords(),
      ));
    }
  }

  void _onSourceUpdated(
      SourceUpdated event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(
        source: event.source,
        isHealthConnected: _stepService.isHealthConnected,
      ));
    }
  }

  Future<void> _onConnectToHealth(
      ConnectToHealth event,
      Emitter<StepState> emit,
      ) async {
    final success = await _stepService.connectToHealth();

    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      if (success) {
        emit(currentState.copyWith(
          source: _stepService.currentSource,
          isHealthConnected: true,
        ));
      } else {
        emit(StepError('Failed to connect to Health app'));
        emit(currentState);
      }
    }
  }

  Future<void> _onDisconnectFromHealth(
      DisconnectFromHealth event,
      Emitter<StepState> emit,
      ) async {
    await _stepService.disconnectFromHealth();

    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(
        source: _stepService.currentSource,
        isHealthConnected: false,
      ));
    }
  }

  void _onRefreshStepRecords(
      RefreshStepRecords event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(
        records: _stepService.getStepRecords(),
      ));
    }
  }

  @override
  Future<void> close() {
    _stepCountSubscription?.cancel();
    _sourceSubscription?.cancel();
    return super.close();
  }
}
*/

class StepBloc extends Bloc<StepEvent, StepState> {
  final StepService _stepService;
  StreamSubscription<int>? _stepCountSubscription;
  StreamSubscription<StepSource>? _sourceSubscription;
  StreamSubscription<List<StepRecord>>? _recordsSubscription;

  StepBloc(this._stepService) : super(StepInitial()) {
    on<InitializeStepTracking>(_onInitialize);
    on<RequestPermissions>(_onRequestPermissions);
    on<StartStepTracking>(_onStartTracking);
    on<ConnectToHealth>(_onConnectToHealth);
    on<DisconnectFromHealth>(_onDisconnectFromHealth);
    on<UpdateStepCount>(_onUpdateStepCount);
    on<UpdateStepSource>(_onUpdateStepSource);
    on<UpdateStepRecords>(_onUpdateStepRecords);
  }

  Future<void> _onInitialize(
      InitializeStepTracking event,
      Emitter<StepState> emit,
      ) async {
    try {
      emit(StepLoading());
      await _stepService.initialize();

      final hasPermissions = await _stepService.requestPermissions();

      if (!hasPermissions) {
        emit(PermissionsNotGranted());
      } else {
        add(StartStepTracking());
      }
    } catch (e) {
      emit(StepError('Failed to initialize: $e'));
    }
  }

  Future<void> _onRequestPermissions(
      RequestPermissions event,
      Emitter<StepState> emit,
      ) async {
    try {
      emit(StepLoading());
      final hasPermissions = await _stepService.requestPermissions();

      if (!hasPermissions) {
        emit(PermissionsNotGranted());
      } else {
        add(StartStepTracking());
      }
    } catch (e) {
      emit(StepError('Failed to request permissions: $e'));
    }
  }

  Future<void> _onStartTracking(
      StartStepTracking event,
      Emitter<StepState> emit,
      ) async {
    try {
      await _stepService.startTracking();

      // Subscribe to step count changes
      _stepCountSubscription = _stepService.stepCountStream.listen((steps) {
        add(UpdateStepCount(steps));
      });

      // Subscribe to source changes
      _sourceSubscription = _stepService.sourceStream.listen((source) {
        add(UpdateStepSource(source));
      });

      // Subscribe to records changes
      _recordsSubscription = _stepService.recordsStream.listen((records) {
        add(UpdateStepRecords(records));
      });

      emit(StepTrackingActive(
        totalSteps: _stepService.totalSteps,
        source: _stepService.currentSource,
        isHealthConnected: _stepService.isHealthConnected,
        records: _stepService.getStepRecords(),
      ));
    } catch (e) {
      emit(StepError('Failed to start tracking: $e'));
    }
  }

  Future<void> _onConnectToHealth(
      ConnectToHealth event,
      Emitter<StepState> emit,
      ) async {
    if (state is StepTrackingActive) {
      try {
        final success = await _stepService.connectToHealth();

        if (success) {
          final currentState = state as StepTrackingActive;
          emit(currentState.copyWith(
            isHealthConnected: true,
            source: _stepService.currentSource,
          ));
        } else {
          emit( StepError('Failed to connect to Health app'));
          // Restore previous state
          if (state is StepError) {
            final currentState = state as StepTrackingActive;
            emit(currentState);
          }
        }
      } catch (e) {
        emit(StepError('Health connection error: $e'));
      }
    }
  }

  Future<void> _onDisconnectFromHealth(
      DisconnectFromHealth event,
      Emitter<StepState> emit,
      ) async {
    if (state is StepTrackingActive) {
      try {
        await _stepService.disconnectFromHealth();

        final currentState = state as StepTrackingActive;
        emit(currentState.copyWith(
          isHealthConnected: false,
          source: _stepService.currentSource,
        ));
      } catch (e) {
        emit(StepError('Failed to disconnect: $e'));
      }
    }
  }

  void _onUpdateStepCount(
      UpdateStepCount event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(totalSteps: event.steps));
    }
  }

  void _onUpdateStepSource(
      UpdateStepSource event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(source: event.source));
    }
  }

  void _onUpdateStepRecords(
      UpdateStepRecords event,
      Emitter<StepState> emit,
      ) {
    if (state is StepTrackingActive) {
      final currentState = state as StepTrackingActive;
      emit(currentState.copyWith(records: event.records));
    }
  }

  @override
  Future<void> close() {
    _stepCountSubscription?.cancel();
    _sourceSubscription?.cancel();
    _recordsSubscription?.cancel();
    return super.close();
  }
}