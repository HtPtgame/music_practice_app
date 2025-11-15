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
      assetPath: 'assets/cat.png',
      requiredCheckInDays: 7,
    ),
    AnimalCollection(
      id: 'dog',
      name: '忠誠小狗',
      assetPath: 'assets/dog.png',
      requiredCheckInDays: 14,
    ),
    AnimalCollection(
      id: 'fox',
      name: '聰明狐狸',
      assetPath: 'assets/fox.png',
      requiredCheckInDays: 21,
    ),
    AnimalCollection(
      id: 'panda',
      name: '萌萌熊貓',
      assetPath: 'assets/panda.png',
      requiredCheckInDays: 28,
    ),
    AnimalCollection(
      id: 'rabbit',
      name: '活潑兔子',
      assetPath: 'assets/rabbit.png',
      requiredCheckInDays: 35,
    ),
    AnimalCollection(
      id: 'bear',
      name: '可愛熊熊',
      assetPath: 'assets/bear.png',
      requiredCheckInDays: 42,
    ),
    AnimalCollection(
      id: 'deer',
      name: '優雅小鹿',
      assetPath: 'assets/deer.png',
      requiredCheckInDays: 49,
    ),
    AnimalCollection(
      id: 'penguin',
      name: '企鵝寶寶',
      assetPath: 'assets/penguin.png',
      requiredCheckInDays: 56,
    ),
    AnimalCollection(
      id: 'koala',
      name: '無尾熊',
      assetPath: 'assets/koala.png',
      requiredCheckInDays: 63,
    ),
    AnimalCollection(
      id: 'raccoon',
      name: '浣熊小可愛',
      assetPath: 'assets/raccoon.png',
      requiredCheckInDays: 70,
    ),
    AnimalCollection(
      id: 'squirrel',
      name: '松鼠',
      assetPath: 'assets/squirrel.png',
      requiredCheckInDays: 77,
    ),
    AnimalCollection(
      id: 'hedgehog',
      name: '刺蝟',
      assetPath: 'assets/hedgehog.png',
      requiredCheckInDays: 84,
    ),
    AnimalCollection(
      id: 'seal',
      name: '海豹',
      assetPath: 'assets/seal.png',
      requiredCheckInDays: 91,
    ),
    AnimalCollection(
      id: 'sheep',
      name: '綿羊',
      assetPath: 'assets/sheep.png',
      requiredCheckInDays: 98,
    ),
    AnimalCollection(
      id: 'lion',
      name: '獅子王',
      assetPath: 'assets/lion.png',
      requiredCheckInDays: 105,
    ),
    AnimalCollection(
      id: 'kangaroo',
      name: '袋鼠',
      assetPath: 'assets/kangaroo.png',
      requiredCheckInDays: 112,
    ),
    AnimalCollection(
      id: 'sloth',
      name: '樹懶',
      assetPath: 'assets/sloth.png',
      requiredCheckInDays: 119,
    ),
    AnimalCollection(
      id: 'guinea_pig',
      name: '天竺鼠',
      assetPath: 'assets/guinea pig.png',
      requiredCheckInDays: 126,
    ),
    AnimalCollection(
      id: 'prairie_dog',
      name: '土撥鼠',
      assetPath: 'assets/prairie dog.png',
      requiredCheckInDays: 133,
    ),
    AnimalCollection(
      id: 'quokka',
      name: '短尾矮袋鼠',
      assetPath: 'assets/Quokka.png',
      requiredCheckInDays: 140,
    ),
    AnimalCollection(
      id: 'fairy',
      name: '小精靈',
      assetPath: 'assets/fairy.png',
      requiredCheckInDays: 147,
    ),
    AnimalCollection(
      id: 'taiwanbear',
      name: '台灣黑熊',
      assetPath: 'assets/taiwanbear.png',
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
        final unlockedAnimal = animal.copyWith(unlockedAt: DateTime.now());
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

  /// 載入已解鎖的動物資料
  void loadUnlockedAnimals(List<Map<String, dynamic>> data) {
    _unlockedAnimals = data.map((json) => AnimalCollection.fromJson(json)).toList();
    notifyListeners();
  }

  /// 匯出已解鎖的動物資料
  List<Map<String, dynamic>> exportUnlockedAnimals() {
    return _unlockedAnimals.map((a) => a.toJson()).toList();
  }
}
