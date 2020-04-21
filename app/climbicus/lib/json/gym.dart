import 'package:json_annotation/json_annotation.dart';

part 'gym.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Gym {
  Gym(this.id, this.name, this.createdAt);

  int id;
  String name;
  DateTime createdAt;

  factory Gym.fromJson(Map<String, dynamic> json) => _$GymFromJson(json);

  Map<String, dynamic> toJson() => _$GymToJson(this);
}
