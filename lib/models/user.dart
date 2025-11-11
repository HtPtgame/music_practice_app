/// 文字筆記資料模型
class MusicNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MusicNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory MusicNote.fromJson(Map<String, dynamic> json) {
    return MusicNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// 使用者資料模型
class User {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // 使用者數據（雲端同步）
  final List<DateTime> checkInDates; // 打卡日期列表
  final Map<String, int> practiceTime; // 練習時間記錄 (日期 -> 秒數)
  final Map<String, dynamic> settings; // 個人化設定
  final List<MusicNote> musicNotes; // 文字筆記

  User({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    List<DateTime>? checkInDates,
    Map<String, int>? practiceTime,
    Map<String, dynamic>? settings,
    List<MusicNote>? musicNotes,
  })  : checkInDates = checkInDates ?? [],
        practiceTime = practiceTime ?? {},
        settings = settings ?? {},
        musicNotes = musicNotes ?? [];

  /// 從 JSON 建立 User 物件
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      checkInDates: (json['checkInDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      practiceTime: (json['practiceTime'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)),
      settings: json['settings'] as Map<String, dynamic>?,
      musicNotes: (json['musicNotes'] as List<dynamic>?)
          ?.map((e) => MusicNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'checkInDates': checkInDates.map((e) => e.toIso8601String()).toList(),
      'practiceTime': practiceTime,
      'settings': settings,
      'musicNotes': musicNotes.map((e) => e.toJson()).toList(),
    };
  }

  /// 複製並更新部分欄位
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<DateTime>? checkInDates,
    Map<String, int>? practiceTime,
    Map<String, dynamic>? settings,
    List<MusicNote>? musicNotes,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      checkInDates: checkInDates ?? this.checkInDates,
      practiceTime: practiceTime ?? this.practiceTime,
      settings: settings ?? this.settings,
      musicNotes: musicNotes ?? this.musicNotes,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}
