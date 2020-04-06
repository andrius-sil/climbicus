import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Route {
  Route(this.id, this.gymId, this.userId, this.grade, this.createdAt);

  int id;
  int gymId;
  int userId;
  String grade;
  DateTime createdAt;

  factory Route.fromJson(Map<String, dynamic> json) =>
      _$RouteFromJson(json);

  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
