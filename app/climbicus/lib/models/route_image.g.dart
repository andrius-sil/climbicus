// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteImage _$RouteImageFromJson(Map<String, dynamic> json) {
  return RouteImage(
    json['id'] as int,
    json['user_id'] as int,
    json['route_id'] as int?,
    DateTime.parse(json['created_at'] as String),
    json['path'] as String,
    json['thumbnail_path'] as String,
  );
}

Map<String, dynamic> _$RouteImageToJson(RouteImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'route_id': instance.routeId,
      'created_at': instance.createdAt.toIso8601String(),
      'path': instance.path,
      'thumbnail_path': instance.thumbnailPath,
    };
