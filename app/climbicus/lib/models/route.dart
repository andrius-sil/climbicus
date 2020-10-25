import 'package:climbicus/utils/route_grades.dart';
import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Route {
  Route(this.id, this.gymId, this.userId, this.category, this.lowerGrade, this.upperGrade, this.avgDifficulty, this.avgQuality, this.createdAt);

  int id;
  int gymId;
  int userId;
  String category;
  String name;
  String lowerGrade;
  String upperGrade;
  String avgDifficulty;
  double avgQuality;
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

  int _gradeIndex(String grade) {
    var splits = grade.split("_");
    assert(splits.length == 2);

    var gradeSystem = GRADE_SYSTEMS[splits[0]];
    return gradeSystem.indexOf(splits[1]);
  }

  int lowerGradeIndex() {
    return _gradeIndex(lowerGrade);
  }

  int upperGradeIndex() {
    return _gradeIndex(upperGrade);
  }

  factory Route.fromJson(Map<String, dynamic> json) =>
      _$RouteFromJson(json);

  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
