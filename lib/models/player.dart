import 'dart:convert';

class Player {
  late int? id;
  final String name;
  final double handicap;
  final List<int> score; // Assuming score is a list of integers

  Player(
      {this.id,
      required this.name,
      required this.handicap,
      required this.score});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'handicap': handicap,
      'score': jsonEncode(score),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      handicap: map['handicap'],
      score: List<int>.from(jsonDecode(map['score'])),
    );
  }
}
