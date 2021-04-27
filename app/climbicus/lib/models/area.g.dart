// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Area _$AreaFromJson(Map<String, dynamic> json) {
  return Area(
    json['id'] as int,
    json['name'] as String,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  )
    ..gymId = json['gym_id'] as int
    ..userId = json['user_id'] as int
    ..imagePath = json['image_path'] as String
    ..thumbnailImagePath = json['thumbnail_image_path'] as String;
}

Map<String, dynamic> _$AreaToJson(Area instance) => <String, dynamic>{
      'id': instance.id,
      'gym_id': instance.gymId,
      'user_id': instance.userId,
      'name': instance.name,
      'image_path': instance.imagePath,
      'thumbnail_image_path': instance.thumbnailImagePath,
      'created_at': instance.createdAt?.toIso8601String(),
    };
