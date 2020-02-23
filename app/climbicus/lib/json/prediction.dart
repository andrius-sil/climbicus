import 'package:json_annotation/json_annotation.dart';

part 'prediction.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Prediction {
  Prediction(this.routeId, this.grade);

  int routeId;
  String grade;

  factory Prediction.fromJson(Map<String, dynamic> json) =>
      _$PredictionFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionToJson(this);
}
