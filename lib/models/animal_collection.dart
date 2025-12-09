import 'package:flutter/foundation.dart';

/// 動物圖鑑模型
class AnimalCollection {
  final String id;
  final String name;
  final String assetPath;
  final int requiredCheckInDays; // 需要打卡幾天才能解鎖
  final DateTime? unlockedAt; // 解鎖時間

  AnimalCollection({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.requiredCheckInDays,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  AnimalCollection copyWith({
    String? id,
    String? name,
    String? assetPath,
    int? requiredCheckInDays,
    DateTime? unlockedAt,
  }) {
    return AnimalCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      requiredCheckInDays: requiredCheckInDays ?? this.requiredCheckInDays,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'requiredCheckInDays': requiredCheckInDays,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory AnimalCollection.fromJson(Map<String, dynamic> json) {
    return AnimalCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      requiredCheckInDays: json['requiredCheckInDays'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

/// 圖鑑管理服務
class AnimalCollectionService extends ChangeNotifier {
  // 所有可收集的動物 (每7天解鎖一隻)
  static final List<AnimalCollection> _allAnimals = [
    AnimalCollection(
      id: 'cat',
      name: '可愛貓咪',
      assetPath: 'assets/animals/cat.png',
      requiredCheckInDays: 7,
    ),
    AnimalCollection(
      id: 'dog',
      name: '忠誠小狗',
      assetPath: 'assets/animals/dog.png',
      requiredCheckInDays: 14,
    ),
    AnimalCollection(
      id: 'fox',
      name: '聰明狐狸',
      assetPath: 'assets/animals/fox.png',
      requiredCheckInDays: 21,
    ),
    AnimalCollection(
      id: 'panda',
      name: '萌萌熊貓',
      assetPath: 'assets/animals/panda.png',
      requiredCheckInDays: 28,
    ),
    AnimalCollection(
      id: 'rabbit',
      name: '活潑兔子',
      assetPath: 'assets/animals/rabbit.png',
      requiredCheckInDays: 35,
    ),
    AnimalCollection(
      id: 'bear',
      name: '可愛熊熊',
      assetPath: 'assets/animals/bear.png',
      requiredCheckInDays: 42,
    ),
    AnimalCollection(
      id: 'deer',
      name: '優雅小鹿',
      assetPath: 'assets/animals/deer.png',
      requiredCheckInDays: 49,
    ),
    AnimalCollection(
      id: 'penguin',
      name: '企鵝寶寶',
      assetPath: 'assets/animals/penguin.png',
      requiredCheckInDays: 56,
    ),
    AnimalCollection(
      id: 'koala',
      name: '無尾熊',
      assetPath: 'assets/animals/koala.png',
      requiredCheckInDays: 63,
    ),
    AnimalCollection(
      id: 'raccoon',
      name: '浣熊小可愛',
      assetPath: 'assets/animals/raccoon.png',
      requiredCheckInDays: 70,
    ),
    AnimalCollection(
      id: 'squirrel',
      name: '松鼠',
      assetPath: 'assets/animals/squirrel.png',
      requiredCheckInDays: 77,
    ),
    AnimalCollection(
      id: 'hedgehog',
      name: '刺蝟',
      assetPath: 'assets/animals/hedgehog.png',
      requiredCheckInDays: 84,
    ),
    AnimalCollection(
      id: 'seal',
      name: '海豹',
      assetPath: 'assets/animals/seal.png',
      requiredCheckInDays: 91,
    ),
    AnimalCollection(
      id: 'sheep',
      name: '綿羊',
      assetPath: 'assets/animals/sheep.png',
      requiredCheckInDays: 98,
    ),
    AnimalCollection(
      id: 'lion',
      name: '獅子王',
      assetPath: 'assets/animals/lion.png',
      requiredCheckInDays: 105,
    ),
    AnimalCollection(
      id: 'kangaroo',
      name: '袋鼠',
      assetPath: 'assets/animals/kangaroo.png',
      requiredCheckInDays: 112,
    ),
    AnimalCollection(
      id: 'sloth',
      name: '樹懶',
      assetPath: 'assets/animals/sloth.png',
      requiredCheckInDays: 119,
    ),
    AnimalCollection(
      id: 'guinea_pig',
      name: '天竺鼠',
      assetPath: 'assets/animals/guinea pig.png',
      requiredCheckInDays: 126,
    ),
    AnimalCollection(
      id: 'prairie_dog',
      name: '土撥鼠',
      assetPath: 'assets/animals/prairie dog.png',
      requiredCheckInDays: 133,
    ),
    AnimalCollection(
      id: 'quokka',
      name: '短尾矮袋鼠',
      assetPath: 'assets/animals/Quokka.png',
      requiredCheckInDays: 140,
    ),
    AnimalCollection(
      id: 'fairy',
      name: '小精靈',
      assetPath: 'assets/animals/fairy.png',
      requiredCheckInDays: 147,
    ),
    AnimalCollection(
      id: 'taiwanbear',
      name: '台灣黑熊',
      assetPath: 'assets/animals/taiwanbear.png',
      requiredCheckInDays: 154,
    ),
  ];

  List<AnimalCollection> _unlockedAnimals = [];

  List<AnimalCollection> get allAnimals => _allAnimals;
  List<AnimalCollection> get unlockedAnimals => _unlockedAnimals;

  int get totalAnimals => _allAnimals.length;
  int get collectedCount => _unlockedAnimals.length;
  double get collectionProgress => collectedCount / totalAnimals;

  /// 根據打卡天數檢查並解鎖動物
  void checkAndUnlockAnimals(int totalCheckInDays) {
    bool hasNewUnlock = false;

    for (var animal in _allAnimals) {
      // 如果已解鎖,跳過
      if (_unlockedAnimals.any((a) => a.id == animal.id)) continue;

      // 檢查是否達到解鎖條件
      if (totalCheckInDays >= animal.requiredCheckInDays) {
        // ✅ 使用當天午夜（只保留日期部分）
        final now = DateTime.now();
        final dateOnly = DateTime(now.year, now.month, now.day);
        final unlockedAnimal = animal.copyWith(unlockedAt: dateOnly);
        _unlockedAnimals.add(unlockedAnimal);
        hasNewUnlock = true;
      }
    }

    if (hasNewUnlock) {
      notifyListeners();
    }
  }

  /// 獲取動物狀態 (已解鎖或未解鎖)
  AnimalCollection getAnimalStatus(String animalId) {
    final unlocked = _unlockedAnimals.firstWhere(
      (a) => a.id == animalId,
      orElse: () => _allAnimals.firstWhere((a) => a.id == animalId),
    );
    return unlocked;
  }

  /// 載入已解鎖的動物資料（從持久化數據）
  void loadUnlockedAnimals(Map<String, String> unlockedData) {
    debugPrint('🦁 AnimalCollectionService.loadUnlockedAnimals 被調用');
    debugPrint('🦁 輸入數據: $unlockedData');
    
    _unlockedAnimals.clear();

    for (var entry in unlockedData.entries) {
      final animalId = entry.key;
      final unlockedAtStr = entry.value;
      debugPrint('🦁 處理動物: $animalId, 時間: $unlockedAtStr');

      final animal = _allAnimals.firstWhere(
        (a) => a.id == animalId,
        orElse: () => throw Exception('找不到動物: $animalId'),
      );

      final parsedDate = DateTime.parse(unlockedAtStr);
      debugPrint('🦁 解析後時間: $parsedDate');
      
      _unlockedAnimals.add(animal.copyWith(
        unlockedAt: parsedDate,
      ));
    }

    debugPrint('🦁 已載入 ${_unlockedAnimals.length} 隻動物');
    for (var animal in _unlockedAnimals) {
      debugPrint('🦁 - ${animal.name}: ${animal.unlockedAt}');
    }

    notifyListeners();
  }

  /// 匯出已解鎖的動物資料（用於持久化）
  Map<String, String> exportUnlockedAnimals() {
    final Map<String, String> result = {};
    for (var animal in _unlockedAnimals) {
      if (animal.unlockedAt != null) {
        // ✅ 確保時間格式統一（只保留日期部分）
        final time = animal.unlockedAt!;
        final dateOnly = DateTime(time.year, time.month, time.day);
        result[animal.id] = dateOnly.toIso8601String();
      }
    }
    return result;
  }
}
