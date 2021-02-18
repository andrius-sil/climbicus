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
    json['category'] as String,
    json['lower_grade'] as String,
    json['upper_grade'] as String,
    json['avg_difficulty'] as String,
    (json['avg_quality'] as num)?.toDouble(),
    json['count_ascents'] as int,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  )..name = json['name'] as String;
}

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'id': instance.id,
      'gym_id': instance.gymId,
      'user_id': instance.userId,
      'category': instance.category,
      'name': instance.name,
      'lower_grade': instance.lowerGrade,
      'upper_grade': instance.upperGrade,
      'avg_difficulty': instance.avgDifficulty,
      'avg_quality': instance.avgQuality,
      'count_ascents': instance.countAscents,
      'created_at': instance.createdAt?.toIso8601String(),
    };
