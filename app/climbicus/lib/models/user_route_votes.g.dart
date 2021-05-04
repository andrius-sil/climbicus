// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_route_votes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRouteVotes _$UserRouteVotesFromJson(Map<String, dynamic> json) {
  return UserRouteVotes(
    json['id'] as int,
    json['route_id'] as int,
    json['user_id'] as int,
    json['gym_id'] as int,
    (json['quality'] as num).toDouble(),
    json['difficulty'] as String,
    DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$UserRouteVotesToJson(UserRouteVotes instance) =>
    <String, dynamic>{
      'id': instance.id,
      'route_id': instance.routeId,
      'user_id': instance.userId,
      'gym_id': instance.gymId,
      'quality': instance.quality,
      'difficulty': instance.difficulty,
      'created_at': instance.createdAt.toIso8601String(),
    };
