class QuranBookmark {
  final int id;
  final int surah;
  final int verse;
  final int page;
  final String? notes;
  final DateTime timestamp;
  final String username;

  QuranBookmark({
    required this.id,
    required this.surah,
    required this.verse,
    required this.page,
    this.notes,
    required this.timestamp,
    required this.username,
  });

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      id: json['id'] ?? 0,
      surah: json['surah'] ?? 1,
      verse: json['verse'] ?? 1,
      page: json['page'] ?? 1,
      notes: json['notes'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surah': surah,
      'verse': verse,
      'page': page,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'username': username,
    };
  }
}

class QuranReadingProgress {
  final int id;
  final int lastPage;
  final DateTime? lastViewed;
  final String username;

  QuranReadingProgress({
    required this.id,
    required this.lastPage,
    this.lastViewed,
    required this.username,
  });

  factory QuranReadingProgress.fromJson(Map<String, dynamic> json) {
    return QuranReadingProgress(
      id: json['id'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      lastViewed: json['last_viewed'] != null
          ? DateTime.parse(json['last_viewed'])
          : null,
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_page': lastPage,
      'last_viewed': lastViewed?.toIso8601String(),
      'username': username,
    };
  }
}
