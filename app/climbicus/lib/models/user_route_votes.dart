import 'package:json_annotation/json_annotation.dart';

part 'user_route_votes.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRouteVotes {
  UserRouteVotes(this.id, this.routeId, this.userId, this.gymId, this.quality, this.difficulty, this.createdAt);

  int id;
  int routeId;
  int userId;
  int gymId;
  double? quality;
  String? difficulty;
  DateTime createdAt;

  factory UserRouteVotes.fromJson(Map<String, dynamic> json) =>
      _$UserRouteVotesFromJson(json);

  Map<String, dynamic> toJson() => _$UserRouteVotesToJson(this);
}
