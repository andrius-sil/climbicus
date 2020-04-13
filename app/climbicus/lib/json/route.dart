import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Route {
  Route(this.id, this.gymId, this.userId, this.category, this.lowerGrade, this.upperGrade, this.createdAt);

  int id;
  int gymId;
  int userId;
  String category;
  String lowerGrade;
  String upperGrade;
  DateTime createdAt;

  String get grade {
    var lGrade = _bareGrade(lowerGrade);
    var uGrade = _bareGrade(upperGrade);

    if (lGrade != uGrade) {
      return "$lGrade - $uGrade";
    }

    return lGrade;
  }

  String _bareGrade(String grade) {
    var splits = grade.split("_");
    assert(splits.length == 2);

    return splits[1];
  }

  factory Route.fromJson(Map<String, dynamic> json) =>
      _$RouteFromJson(json);

  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
