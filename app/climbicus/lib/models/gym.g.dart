// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gym _$GymFromJson(Map<String, dynamic> json) {
  return Gym(
    json['id'] as int,
    json['name'] as String,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  )
    ..hasBouldering = json['has_bouldering'] as bool
    ..hasSport = json['has_sport'] as bool;
}

Map<String, dynamic> _$GymToJson(Gym instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'has_bouldering': instance.hasBouldering,
      'has_sport': instance.hasSport,
      'created_at': instance.createdAt?.toIso8601String(),
    };
