import 'package:hive/hive.dart';

part 'step_record.g.dart';

@HiveType(typeId: 0)
class StepRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int value;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime endTime;

  @HiveField(4)
  final bool isSync;

  @HiveField(5)
  final String source; // 'pedometer' or 'health'

  StepRecord({
    required this.id,
    required this.value,
    required this.startTime,
    required this.endTime,
    required this.isSync,
    required this.source,
  });
}