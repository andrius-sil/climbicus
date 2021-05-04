import 'package:json_annotation/json_annotation.dart';

part 'gym.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Gym {
  Gym(this.id, this.name, this.hasBouldering, this.hasSport, this.createdAt);

  int id;
  String name;
  bool hasBouldering;
  bool hasSport;
  DateTime createdAt;

  factory Gym.fromJson(Map<String, dynamic> json) => _$GymFromJson(json);

  Map<String, dynamic> toJson() => _$GymToJson(this);
}
