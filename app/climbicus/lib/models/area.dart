import 'package:json_annotation/json_annotation.dart';

part 'area.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Area {
  Area(this.id, this.name, this.createdAt);

  int id;
  int gymId;
  int userId;
  String name;
  String imagePath;
  String thumbnailImagePath;
  DateTime createdAt;

  factory Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);

  Map<String, dynamic> toJson() => _$AreaToJson(this);
}
