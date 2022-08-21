import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'points.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SerializableOffset extends Offset {
  SerializableOffset(double dx, double dy) : super(dx, dy);

  SerializableOffset.fromOffset(Offset offset) : super(offset.dx, offset.dy);

  factory SerializableOffset.fromJson(Map<String, dynamic> json) =>
      _$SerializableOffsetFromJson(json);

  Map<String, dynamic> toJson() => _$SerializableOffsetToJson(this);

  // factory SerializableOffset.fromJson(Map<String, dynamic> json) {
  //   throw UnimplementedError();
  // }
  //
  // // Map<String, dynamic> toJson() {
  // String toJson() {
  //   return "(${this.dx},${this.dy})";
  // }
}

// import 'package:json_annotation/json_annotation.dart';

// @JsonSerializable(fieldRename: FieldRename.snake)
// class Points extends List<Offset> {
//   // Points(this.points);
//   //
//   // // @JsonOffset()
//   // List<Offset> points = [];
//   //
//   // Points map(Points other) => Points(other.points.map())
//   // Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> convert(K key, V value));
//
//   factory Points.fromJson(Map<String, dynamic> json) {
//     throw UnimplementedError();
//   }
//
//   Map<String, dynamic> toJson() {
//     throw UnimplementedError();
//   }
// }


// class JsonOffset implements JsonConverter<List<Offset>, String> {
//   const JsonOffset();
//
//   @override
//   List<Offset> fromJson(String json) {
//     // TODO: implement fromJson
//     throw UnimplementedError();
//   }
//
//   @override
//   String toJson(List<Offset> object) {
//     // TODO: implement toJson
//     throw UnimplementedError();
//   }
//
//   // @override
//   // Offset fromJson(String json) {
//   //   return Offset(0, 0);
//   // }
//   //
//   // @override
//   // String toJson(Offset object) {
//   //   return "x";
//   // }
//
//   // Points _$PointsFromJson(Map<String, dynamic> json) {
//   //   return Points(
//   //     (json['points'] as List<dynamic>).map((e) => e as int).toList(),
//   //   );
//   // }
//   //
//   // Map<String, dynamic> _$PointsToJson(Points instance) => <String, dynamic>{
//   //   'points': instance.points,
//   // };
//
// }
