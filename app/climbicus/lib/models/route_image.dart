import 'package:json_annotation/json_annotation.dart';

part 'route_image.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RouteImage {
  RouteImage(this.id, this.userId, this.routeId, this.createdAt, this.path);

  int id;
  int userId;
  int routeId;
  DateTime createdAt;
  String path;
  String thumbnailPath;

  factory RouteImage.fromJson(Map<String, dynamic> json) =>
      _$RouteImageFromJson(json);

  Map<String, dynamic> toJson() => _$RouteImageToJson(this);
}
