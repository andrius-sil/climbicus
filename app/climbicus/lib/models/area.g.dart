// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Area _$AreaFromJson(Map<String, dynamic> json) {
  return Area(
    json['id'] as int,
    json['gym_id'] as int,
    json['user_id'] as int,
    json['name'] as String,
    json['image_path'] as String,
    json['thumbnail_image_path'] as String,
    DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$AreaToJson(Area instance) => <String, dynamic>{
      'id': instance.id,
      'gym_id': instance.gymId,
      'user_id': instance.userId,
      'name': instance.name,
      'image_path': instance.imagePath,
      'thumbnail_image_path': instance.thumbnailImagePath,
      'created_at': instance.createdAt.toIso8601String(),
    };
