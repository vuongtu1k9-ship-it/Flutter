class User {
  final String uid;
  final String name;
  final String? picture;
  final int elo;
  final bool online;

  User({
    required this.uid,
    required this.name,
    this.picture,
    this.elo = 1200,
    this.online = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'Kỳ thủ',
      picture: json['picture'] ?? json['avatar'],
      elo: json['elo'] ?? 1200,
      online: json['online'] ?? false,
    );
  }
}

class GameSummary {
  final String roomId;
  final String status;
  final String? redName;
  final String? blackName;
  final int spectators;
  final bool started;
  final List<dynamic>? thumbBoard;
  final int? createdAt;

  GameSummary({
    required this.roomId,
    required this.status,
    this.redName,
    this.blackName,
    this.spectators = 0,
    this.started = false,
    this.thumbBoard,
    this.createdAt,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    final players = json['players'] ?? {};
    return GameSummary(
      roomId: json['roomId'] ?? '',
      status: json['status'] ?? 'open',
      redName: players['redName'],
      blackName: players['blackName'],
      spectators: json['spectators'] ?? 0,
      started: json['started'] ?? false,
      thumbBoard: json['thumbBoard'],
      createdAt: json['createdAt'],
    );
  }
}

class Puzzle {
  final String uid;
  final String name;
  final int level;
  final List<dynamic>? board;
  final String? fen;

  Puzzle({
    required this.uid,
    required this.name,
    this.level = 1,
    this.board,
    this.fen,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      uid: json['uid'] ?? json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Thế cờ',
      level: json['level'] ?? 1,
      board: json['board'],
      fen: json['fen'],
    );
  }
}

class Tournament {
  final String id;
  final String name;
  final String status;
  final int playersCount;
  final DateTime? startDate;
  final String? description;

  Tournament({
    required this.id,
    required this.name,
    required this.status,
    this.playersCount = 0,
    this.startDate,
    this.description,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Giải đấu',
      status: json['status'] ?? 'open',
      playersCount: json['playersCount'] ?? 0,
      startDate: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      description: json['description'],
    );
  }
}
