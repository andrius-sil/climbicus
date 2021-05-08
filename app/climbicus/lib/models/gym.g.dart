// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gym _$GymFromJson(Map<String, dynamic> json) {
  return Gym(
    json['id'] as int,
    json['name'] as String,
    json['has_bouldering'] as bool,
    json['has_sport'] as bool,
    DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$GymToJson(Gym instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'has_bouldering': instance.hasBouldering,
      'has_sport': instance.hasSport,
      'created_at': instance.createdAt.toIso8601String(),
    };
