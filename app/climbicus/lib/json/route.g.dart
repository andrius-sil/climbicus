// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) {
  return Route(
    json['id'] as int,
    json['gym_id'] as int,
    json['user_id'] as int,
    json['grade'] as String,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'id': instance.id,
      'gym_id': instance.gymId,
      'user_id': instance.userId,
      'grade': instance.grade,
      'created_at': instance.createdAt?.toIso8601String(),
    };
