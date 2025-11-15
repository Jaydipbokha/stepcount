import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_record.dart';
import '../models/step_source.dart';

class StepService {
  static final StepService _instance = StepService._internal();
  factory StepService() => _instance;
  StepService._internal();

  // Stream controllers
  final _stepCountController = StreamController<int>.broadcast();
  final _sourceController = StreamController<StepSource>.broadcast();

  Stream<int> get stepCountStream => _stepCountController.stream;
  Stream<StepSource> get sourceStream => _sourceController.stream;

  // Pedometer
  StreamSubscription<StepCount>? _pedometerSubscription;
  int _pedometerStepCount = 0;
  int _pedometerOffset = 0;
  int _lastPedometerValue = 0;

  // Health
  Health? _health;
  bool _isHealthConnected = false;
  int _healthStepCount = 0;
  int _lastHealthStepCount = 0;

  // Timer
  Timer? _dataStorageTimer;

  // Current state
  StepSource _currentSource = StepSource.pedometer;
  int _totalStepWalked = 0;

  // Hive box
  Box<StepRecord>? _stepRecordBox;

  // SharedPreferences keys
  static const String _totalStepsKey = 'total_steps_walked';
  static const String _healthConnectedKey = 'health_connected';
  static const String _pedometerOffsetKey = 'pedometer_offset';
  static const String _lastPedometerValueKey = 'last_pedometer_value';
  static const String _lastHealthStepCountKey = 'last_health_step_count';

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(StepRecordAdapter());
    _stepRecordBox = await Hive.openBox<StepRecord>('step_records');

    _health = Health();

    // Load saved state
    await _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _totalStepWalked = prefs.getInt(_totalStepsKey) ?? 0;
    _isHealthConnected = prefs.getBool(_healthConnectedKey) ?? false;
    _pedometerOffset = prefs.getInt(_pedometerOffsetKey) ?? 0;
    _lastPedometerValue = prefs.getInt(_lastPedometerValueKey) ?? 0;
    _lastHealthStepCount = prefs.getInt(_lastHealthStepCountKey) ?? 0;

    _currentSource = _isHealthConnected ? StepSource.health : StepSource.pedometer;
    _sourceController.add(_currentSource);
    _stepCountController.add(_totalStepWalked);
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startTracking() async {
    // Start pedometer
    _pedometerSubscription = Pedometer.stepCountStream.listen(
      _onPedometerStepCount,
      onError: _onPedometerError,
    );

    // If health was previously connected, reconnect
    if (_isHealthConnected) {
      await _connectToHealth();
    }

    // Start timer for data storage
    _startDataStorageTimer();
  }

  void _onPedometerStepCount(StepCount event) {
    final currentPedometerValue = event.steps;

    // Initialize offset on first reading
    if (_lastPedometerValue == 0) {
      _lastPedometerValue = currentPedometerValue;
      _pedometerOffset = currentPedometerValue;
      _savePedometerState();
      return;
    }

    // Calculate steps since last reading
    final stepsDiff = currentPedometerValue - _lastPedometerValue;
    _lastPedometerValue = currentPedometerValue;

    if (stepsDiff > 0) {
      _pedometerStepCount = currentPedometerValue - _pedometerOffset;

      // Only update total if pedometer is the current source
      if (_currentSource == StepSource.pedometer) {
        _totalStepWalked += stepsDiff;
        _saveAndBroadcastSteps();
      }
    }

    _savePedometerState();
  }

  void _onPedometerError(error) {
    print('Pedometer Error: $error');
  }

  Future<bool> connectToHealth() async {
    return await _connectToHealth();
  }

  Future<bool> _connectToHealth() async {
    try {
      final types = [HealthDataType.STEPS];
      final permissions = types.map((type) => HealthDataAccess.READ).toList();

      bool authorized = await _health!.requestAuthorization(types, permissions: permissions);

      if (!authorized) {
        return false;
      }

      // Get initial health step count for today
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final healthData = await _health!.getHealthDataFromTypes(
        types: types,
        startTime: midnight,
        endTime: now,
      );

      _healthStepCount = 0;
      for (var data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          _healthStepCount += (data.value as num).toInt();
        }
      }

      // When connecting to health, we need to transition properly
      if (_currentSource == StepSource.pedometer) {
        // Switch to health source
        _currentSource = StepSource.health;
        _lastHealthStepCount = _healthStepCount;

        // Reset pedometer offset to current value to avoid double counting
        _pedometerOffset = _lastPedometerValue;
      }

      _isHealthConnected = true;
      await _saveHealthState();
      _sourceController.add(_currentSource);

      // Start polling health data
      _startHealthPolling();

      return true;
    } catch (e) {
      print('Health Connection Error: $e');
      return false;
    }
  }

  Timer? _healthPollingTimer;

  void _startHealthPolling() {
    _healthPollingTimer?.cancel();
    _healthPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isHealthConnected && _currentSource == StepSource.health) {
        await _updateHealthSteps();
      }
    });
  }

  Future<void> _updateHealthSteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final healthData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: midnight,
        endTime: now,
      );

      int currentHealthSteps = 0;
      for (var data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          currentHealthSteps += (data.value as num).toInt();
        }
      }

      // Calculate new steps since last check
      final stepsDiff = currentHealthSteps - _lastHealthStepCount;

      if (stepsDiff > 0) {
        _healthStepCount = currentHealthSteps;
        _totalStepWalked += stepsDiff;
        _lastHealthStepCount = currentHealthSteps;

        await _saveAndBroadcastSteps();
        await _saveHealthState();
      }
    } catch (e) {
      print('Health Update Error: $e');
    }
  }

  Future<void> disconnectFromHealth() async {
    _healthPollingTimer?.cancel();

    // When disconnecting, switch back to pedometer
    _currentSource = StepSource.pedometer;
    _isHealthConnected = false;

    // Reset pedometer offset to continue from current position
    _pedometerOffset = _lastPedometerValue;

    await _saveHealthState();
    await _savePedometerState();
    _sourceController.add(_currentSource);
  }

  void _startDataStorageTimer() {
    _dataStorageTimer?.cancel();
    _dataStorageTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _storeStepData();
    });
  }

  Future<void> _storeStepData() async {
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(minutes: 1));

    // Calculate steps in last minute
    int stepsInLastMinute = 0;

    if (_currentSource == StepSource.pedometer) {
      // Store pedometer data
      stepsInLastMinute = _pedometerStepCount;
    } else {
      // Store health data
      stepsInLastMinute = _healthStepCount;
    }

    final record = StepRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      value: stepsInLastMinute,
      startTime: startTime,
      endTime: now,
      isSync: false,
      source: _currentSource == StepSource.pedometer ? 'pedometer' : 'health',
    );

    await _stepRecordBox?.add(record);
  }

  Future<void> _saveAndBroadcastSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalStepsKey, _totalStepWalked);
    _stepCountController.add(_totalStepWalked);
  }

  Future<void> _savePedometerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pedometerOffsetKey, _pedometerOffset);
    await prefs.setInt(_lastPedometerValueKey, _lastPedometerValue);
  }

  Future<void> _saveHealthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthConnectedKey, _isHealthConnected);
    await prefs.setInt(_lastHealthStepCountKey, _lastHealthStepCount);
  }

  List<StepRecord> getStepRecords() {
    return _stepRecordBox?.values.toList() ?? [];
  }

  bool get isHealthConnected => _isHealthConnected;
  int get totalSteps => _totalStepWalked;
  StepSource get currentSource => _currentSource;

  void dispose() {
    _pedometerSubscription?.cancel();
    _dataStorageTimer?.cancel();
    _healthPollingTimer?.cancel();
    _stepCountController.close();
    _sourceController.close();
  }
}