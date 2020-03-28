// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_route_log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRouteLogEntry _$UserRouteLogEntryFromJson(Map<String, dynamic> json) {
  return UserRouteLogEntry(
    json['route_id'] as int,
    json['grade'] as String,
    json['status'] as String,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$UserRouteLogEntryToJson(UserRouteLogEntry instance) =>
    <String, dynamic>{
      'route_id': instance.routeId,
      'grade': instance.grade,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };
