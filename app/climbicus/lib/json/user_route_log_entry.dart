import 'package:json_annotation/json_annotation.dart';

part 'user_route_log_entry.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRouteLogEntry {
  UserRouteLogEntry(this.routeId, this.grade, this.status, this.createdAt);

  int routeId;
  String grade;
  String status;
  String createdAt;

  factory UserRouteLogEntry.fromJson(Map<String, dynamic> json) =>
      _$UserRouteLogEntryFromJson(json);

  Map<String, dynamic> toJson() => _$UserRouteLogEntryToJson(this);
}
