// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepRecordAdapter extends TypeAdapter<StepRecord> {
  @override
  final int typeId = 0;

  @override
  StepRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepRecord(
      id: fields[0] as String,
      value: fields[1] as int,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      isSync: fields[4] as bool,
      source: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StepRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.isSync)
      ..writeByte(5)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
