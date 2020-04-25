import 'package:json_annotation/json_annotation.dart';

part 'user_route_log.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRouteLog {
  UserRouteLog(this.id, this.routeId, this.userId, this.gymId, this.completed, this.numAttempts, this.createdAt);

  int id;
  int routeId;
  int userId;
  int gymId;
  bool completed;
  int numAttempts;
  DateTime createdAt;

  factory UserRouteLog.fromJson(Map<String, dynamic> json) =>
      _$UserRouteLogFromJson(json);

  Map<String, dynamic> toJson() => _$UserRouteLogToJson(this);
}
