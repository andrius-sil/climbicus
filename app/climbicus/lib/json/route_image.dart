import 'package:json_annotation/json_annotation.dart';

part 'route_image.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RouteImage {
  RouteImage(this.routeImageId, this.b64Image);

  int routeImageId;
  String b64Image;

  factory RouteImage.fromJson(Map<String, dynamic> json) => _$RouteImageFromJson(json);
  Map<String, dynamic> toJson() => _$RouteImageToJson(this);
}
