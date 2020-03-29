// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) {
  return Route(
    json['grade'] as String,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    json['user_id'] as int,
  );
}

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'grade': instance.grade,
      'created_at': instance.createdAt?.toIso8601String(),
      'user_id': instance.userId,
    };
