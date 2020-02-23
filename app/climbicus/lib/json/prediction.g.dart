// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prediction _$PredictionFromJson(Map<String, dynamic> json) {
  return Prediction(
    json['route_id'] as int,
    json['grade'] as String,
  );
}

Map<String, dynamic> _$PredictionToJson(Prediction instance) =>
    <String, dynamic>{
      'route_id': instance.routeId,
      'grade': instance.grade,
    };
