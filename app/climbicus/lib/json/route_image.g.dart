// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteImage _$RouteImageFromJson(Map<String, dynamic> json) {
  return RouteImage(
    json['route_image_id'] as int,
    json['b64_image'] as String,
  );
}

Map<String, dynamic> _$RouteImageToJson(RouteImage instance) =>
    <String, dynamic>{
      'route_image_id': instance.routeImageId,
      'b64_image': instance.b64Image,
    };
