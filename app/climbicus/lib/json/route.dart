import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Route {
  Route(this.grade, this.createdAt);

  String grade;
  DateTime createdAt;

  factory Route.fromJson(Map<String, dynamic> json) =>
      _$RouteFromJson(json);

  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
