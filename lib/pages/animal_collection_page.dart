import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_collection.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import '../services/user_data_sync_service.dart';
import '../services/sound_effect_service.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
// import '../widgets/unlock_animation_dialog.dart';

/// 動物圖鑑頁面
class AnimalCollectionPage extends StatefulWidget {
  const AnimalCollectionPage({super.key});

  @override
  State<AnimalCollectionPage> createState() => _AnimalCollectionPageState();
}

/// 根據動物ID獲取翻譯後的名稱（靜態輔助方法）
String getAnimalName(String animalId, AppLocalizations? l10n) {
  switch (animalId) {
    case 'cat': return l10n?.animalCat ?? '樂句 / Legato';
    case 'dog': return l10n?.animalDog ?? '快板 / Allegro';
    case 'fox': return l10n?.animalFox ?? '顫音 / Tremolo';
    case 'panda': return l10n?.animalPanda ?? '圓舞曲 / Valse';
    case 'rabbit': return l10n?.animalRabbit ?? '斷奏 / Staccato';
    case 'bear': return l10n?.animalBear ?? '低音 / Basso';
    case 'deer': return l10n?.animalDeer ?? '優美 / Dolce';
    case 'penguin': return l10n?.animalPenguin ?? '進行曲 / Marcia';
    case 'koala': return l10n?.animalKoala ?? '慢板 / Adagio';
    case 'raccoon': return l10n?.animalRaccoon ?? '夜曲 / Notturno';
    case 'squirrel': return l10n?.animalSquirrel ?? '急板 / Presto';
    case 'hedgehog': return l10n?.animalHedgehog ?? '斷音 / Pizzicato';
    case 'seal': return l10n?.animalSeal ?? '滑音 / Glissando';
    case 'sheep': return l10n?.animalSheep ?? '柔音 / Piano';
    case 'lion': return l10n?.animalLion ?? '強音 / Forte';
    case 'kangaroo': return l10n?.animalKangaroo ?? '跳音 / Saltando';
    case 'sloth': return l10n?.animalSloth ?? '極慢板 / Grave';
    case 'guinea_pig': return l10n?.animalGuineaPig ?? '顫音 / Vibrato';
    case 'prairie_dog': return l10n?.animalPrairieDog ?? '合唱 / Coro';
    case 'quokka': return l10n?.animalQuokka ?? '小曲 / Scherzando';
    case 'fairy': return l10n?.animalFairy ?? '幻想曲 / Fantasia';
    case 'taiwanbear': return l10n?.animalTaiwanBear ?? '雄壯 / Maestoso';
    default: return '???';
  }
}

/// 分離中英文名稱（返回 ['中文', '英文']）
List<String> splitAnimalName(String fullName) {
  if (fullName.contains(' / ')) {
    final parts = fullName.split(' / ');
    return [parts[0].trim(), parts[1].trim()];
  }
  return [fullName, '']; // 如果沒有 / 分隔，僅返回單一名稱
}

/// 根據動物ID獲取命名理由（靜態輔助方法）
String getAnimalReason(String animalId, AppLocalizations? l10n) {
  switch (animalId) {
    case 'cat': return l10n?.animalReasonCat ?? '貓咪動作流暢優雅，如音樂中連貫不斷的樂句';
    case 'dog': return l10n?.animalReasonDog ?? '小狗活潑好動，充滿快板般的歡快節奏';
    case 'fox': return l10n?.animalReasonFox ?? '狐狸機敏靈動，像快速重複的顫音效果';
    case 'panda': return l10n?.animalReasonPanda ?? '熊貓動作憙態可掬，如圓舞曲般優雅緩慢';
    case 'rabbit': return l10n?.animalReasonRabbit ?? '兔子跳躍輕快，如短促分離的斷奏音符';
    case 'bear': return l10n?.animalReasonBear ?? '熊體型龐大沉穩，如樂曲中的低音聲部';
    case 'deer': return l10n?.animalReasonDeer ?? '小鹿姿態輕盈溫柔，如甜美柔和的音樂表情';
    case 'penguin': return l10n?.animalReasonPenguin ?? '企鵝搖擺步伐整齊，如軍隊行進的進行曲';
    case 'koala': return l10n?.animalReasonKoala ?? '無尾熊動作緩慢悠閑，如舒緩的慢板樂章';
    case 'raccoon': return l10n?.animalReasonRaccoon ?? '浣熊夜行性動物，如寧靜神秘的夜曲';
    case 'squirrel': return l10n?.animalReasonSquirrel ?? '松鼠動作敏捷快速，如極快速的急板樂段';
    case 'hedgehog': return l10n?.animalReasonHedgehog ?? '刺蝟渾身尖刺，如撥弦產生的斷續音效';
    case 'seal': return l10n?.animalReasonSeal ?? '海豹在水中滑行流暢，如音高連續滑動';
    case 'sheep': return l10n?.animalReasonSheep ?? '綿羊溫順安靜，如輕柔的弱音演奏';
    case 'lion': return l10n?.animalReasonLion ?? '獅子威武雄壯，如響亮有力的強音';
    case 'kangaroo': return l10n?.animalReasonKangaroo ?? '袋鼠擅長跳躍，如彈跳般的音樂奏法';
    case 'sloth': return l10n?.animalReasonSloth ?? '樹懶行動極其緩慢，如莊嚴緩慢的極慢板';
    case 'guinea_pig': return l10n?.animalReasonGuineaPig ?? '天竺鼠叫聲連續顫動，如聲音的輕微震盪';
    case 'prairie_dog': return l10n?.animalReasonPrairieDog ?? '草原犬鼠群居互動，如多聲部的合唱效果';
    case 'quokka': return l10n?.animalReasonQuokka ?? '短尾矮袋鼠表情可愛俴皮，如詼諧輕快的小曲';
    case 'fairy': return l10n?.animalReasonFairy ?? '精靈神秘夢幻，如自由即興的幻想曲';
    case 'taiwanbear': return l10n?.animalReasonTaiwanBear ?? '台灣黑熊威嚴莊重，如莊嚴宏偉的音樂風格';
    default: return '';
  }
}

class _AnimalCollectionPageState extends State<AnimalCollectionPage> with TickerProviderStateMixin {
  late AnimalCollectionService _collectionService;
  final UserDataSyncService _syncService = UserDataSyncService();
  bool _isLoading = true;
  
  // 用於獲取每個動物卡片的位置
  final Map<String, GlobalKey> _animalKeys = {};
  final ScrollController _scrollController = ScrollController();

  // 使用首頁的打卡數據
  Set<String> _checkedDates = {};
  int _consecutiveDays = 0;
  
  // 視覺上暫時鎖定的動物（用於動畫播放前保持灰色）
  final Set<String> _visuallyLockedAnimals = {};
  // 測試模式下暫時解鎖的動物
  final Set<String> _testUnlockedAnimals = {};

  @override
  void initState() {
    super.initState();
    _collectionService = AnimalCollectionService();
    
    // 初始化 Keys
    for (var animal in _collectionService.allAnimals) {
      _animalKeys[animal.id] = GlobalKey();
    }
    
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次頁面顯示時重新載入數據（捕捉打卡變化）
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
      final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;

      // 載入已解鎖動物（從本地或雲端）
      await _loadUnlockedAnimals();

      // 記錄舊的解鎖列表以便比對
      final oldUnlockedIds = _collectionService.unlockedAnimals.map((a) => a.id).toSet();

      setState(() {
        _checkedDates = checkedDatesJson.toSet();
        _consecutiveDays = consecutiveDays;
        // ✅ 根據打卡天數檢查並補救漏解鎖的動物
        // 這是一個安全機制：如果之前因為某些原因（如 App 崩潰）沒有解鎖應該解鎖的動物，
        // 這裡會補救。但不會重複解鎖已經解鎖的動物（checkAndUnlockAnimals 內部會檢查）
        _collectionService.checkAndUnlockAnimals(_checkedDates.length);
        _isLoading = false;
      });

      // 檢查是否有新解鎖的動物（補救機制觸發時才會有）
      final newUnlockedAnimals = _collectionService.unlockedAnimals
          .where((a) => !oldUnlockedIds.contains(a.id))
          .toList();

      if (newUnlockedAnimals.isNotEmpty) {
        // 將新解鎖的動物暫時標記為視覺鎖定
        setState(() {
          for (var animal in newUnlockedAnimals) {
            _visuallyLockedAnimals.add(animal.id);
          }
        });
        
        // 獲得新動物，顯示慶祝動畫
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          for (var animal in newUnlockedAnimals) {
            await _playMagicAnimation(animal.id);
            // 每個動畫之間稍微間隔
            await Future.delayed(const Duration(milliseconds: 500));
          }
        });
      }

      // 保存並同步新解鎖的動物
      await _saveAndSyncUnlockedAnimals();
    } catch (e) {
      debugPrint('載入動物圖鑑數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 載入已解鎖動物數據
  Future<void> _loadUnlockedAnimals() async {
    final user = authService.currentUser;
    debugPrint('🐾 載入動物解鎖數據...');
    debugPrint('🐾 目前使用者: ${user?.email ?? "訪客"}');
    
    if (user != null) {
      // 已登入用戶：從雲端數據載入（即使為空也要載入，避免使用本地舊數據）
      debugPrint('🐾 從雲端載入: ${user.unlockedAnimals}');
      _collectionService.loadUnlockedAnimals(user.unlockedAnimals);
    } else {
      // 訪客模式：從本地 SharedPreferences 載入
      final prefs = await SharedPreferences.getInstance();
      final unlockedJson = prefs.getString('unlocked_animals');
      debugPrint('🐾 本地數據: $unlockedJson');
      
      if (unlockedJson != null && unlockedJson.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded =
              Map<String, dynamic>.from(jsonDecode(unlockedJson));
          final Map<String, String> unlockedAnimals =
              decoded.map((key, value) => MapEntry(key, value as String));
          debugPrint('🐾 解析後: $unlockedAnimals');
          _collectionService.loadUnlockedAnimals(unlockedAnimals);
        } catch (e) {
          debugPrint('載入本地動物解鎖數據失敗: $e');
          // 載入失敗時，確保載入空數據
          _collectionService.loadUnlockedAnimals({});
        }
      } else {
        // 本地無數據，載入空數據
        debugPrint('🐾 本地無數據，載入空解鎖列表');
        _collectionService.loadUnlockedAnimals({});
      }
    }
  }

  /// 保存並同步已解鎖動物
  Future<void> _saveAndSyncUnlockedAnimals() async {
    final unlockedData = _collectionService.exportUnlockedAnimals();

    // 保存到本地
    final prefs = await SharedPreferences.getInstance();
    final unlockedJson = jsonEncode(unlockedData);
    await prefs.setString('unlocked_animals', unlockedJson);

    // 如果已登入，同步到雲端
    final user = authService.currentUser;
    if (user != null) {
      try {
        await _syncService.syncUnlockedAnimals(unlockedData);
        debugPrint('✅ 動物解鎖數據已同步');
      } catch (e) {
        debugPrint('同步動物解鎖數據失敗: $e');
      }
    }
  }

  /// 測試解鎖動畫
  void _testUnlockAnimation() {
    // 隨機選一個動物來測試
    // 優先選未解鎖的，如果都解鎖了就選最後一個
    final lockedAnimals = _collectionService.allAnimals.where((a) => !_collectionService.getAnimalStatus(a.id).isUnlocked).toList();
    final target = lockedAnimals.isNotEmpty 
        ? lockedAnimals.first 
        : _collectionService.allAnimals.last;
        
    debugPrint('🧪 測試解鎖動畫: ${target.name}');
    
    // 測試時，先把它設為視覺鎖定，這樣動畫結束後才會變亮
    setState(() {
      _visuallyLockedAnimals.add(target.id);
      _testUnlockedAnimals.add(target.id);
    });
    
    _playMagicAnimation(target.id);
  }

  /// 播放魔法解鎖動畫
  Future<void> _playMagicAnimation(String animalId) async {
    final key = _animalKeys[animalId];
    if (key == null) return;

    // 嘗試滾動到目標位置
    if (key.currentContext == null) {
       final index = _collectionService.allAnimals.indexWhere((a) => a.id == animalId);
       if (index != -1) {
         // 估算位置並滾動 (假設每行3個，aspect ratio 0.75)
         // 獲取螢幕寬度來計算高度
         final screenWidth = MediaQuery.of(context).size.width;
         final itemWidth = (screenWidth - 32 - 24) / 3; // padding 16*2, spacing 12*2
         final itemHeight = itemWidth / 0.75;
         final row = index ~/ 3;
         // 加上 header 高度 (StatsCard + AppBar) - 粗略估計 300
         final offset = row * (itemHeight + 12) + 250; 
         
         await _scrollController.animateTo(
           offset, 
           duration: const Duration(milliseconds: 500), 
           curve: Curves.easeInOut
         );
         await Future.delayed(const Duration(milliseconds: 300));
       }
    }

    if (!mounted) return;

    // 再次檢查 context
    final targetKeyContext = key.currentContext;
    if (targetKeyContext == null) {
      debugPrint('無法找到目標動物的 Context: $animalId');
      return;
    }

    // 確保可見
    await Scrollable.ensureVisible(
      targetKeyContext, 
      alignment: 0.5, // 垂直置中
      duration: const Duration(milliseconds: 500),
    );
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    final targetCenter = targetPosition + Offset(targetSize.width / 2, targetSize.height / 2);
    
    // 起點：螢幕底部隨機位置
    final size = MediaQuery.of(context).size;
    final random = Random();
    // 在底部寬度 20%~80% 範圍內隨機
    final startX = size.width * 0.2 + random.nextDouble() * (size.width * 0.6);
    final startPosition = Offset(startX, size.height);

    // 顯示 Overlay
    OverlayEntry? overlayEntry;
    
    // 創建 Completer 來等待動畫結束
    // 雖然 Overlay 是異步的，但我們希望 _playMagicAnimation 等待它完成
    // 不過這裡我們不阻塞，讓它自然回調
    
    overlayEntry = OverlayEntry(
      builder: (ctx) => _MagicParticleOverlay(
        startPosition: startPosition,
        targetPosition: targetCenter,
        onUnlock: () {
          // 動畫到達目標，觸發解鎖動畫
          if (mounted) {
            setState(() {
              _visuallyLockedAnimals.remove(animalId);
            });
          }
        },
        onComplete: () {
          overlayEntry?.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    
    // 等待動畫時間，以便如果是連續播放，不會重疊太多
    await Future.delayed(const Duration(milliseconds: 2500));
  }

  /// 顯示解鎖動物的慶祝動畫 (舊版，保留備用)
  // void _showUnlockAnimation(AnimalCollection animal) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => UnlockAnimationDialog(animal: animal),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n?.animalCollectionTitle ?? '動物圖鑑',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[400], // 與下方統計卡片統一
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      // 當頁面即將顯示時重新載入數據（處理從首頁打卡返回的情況）
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // 頁面已經 pop，不需要額外處理
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n?.animalCollectionTitle ?? '動物圖鑑',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[400], // 與下方統計卡片統一
          actions: [
            // 測試按鈕
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              tooltip: '測試解鎖動畫',
              onPressed: _testUnlockAnimation,
            ),
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 統計資訊卡片(可滑動)
              SliverToBoxAdapter(
                child: _buildStatsCard(l10n),
              ),

              // 動物卡片網格
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final animal = _collectionService.allAnimals[index];
                    final status =
                        _collectionService.getAnimalStatus(animal.id);
                    // 如果在視覺鎖定列表中，強制顯示為未解鎖
                    final isUnlocked = (status.isUnlocked || _testUnlockedAnimals.contains(animal.id)) && 
                        !_visuallyLockedAnimals.contains(animal.id);
                    final totalDays = _checkedDates.length;

                    return _AnimalCard(
                      key: _animalKeys[animal.id], // 綁定 Key
                      animal: status, // ✅ 使用 status（含 unlockedAt）而不是 animal
                      isUnlocked: isUnlocked,
                      currentDays: totalDays,
                      l10n: l10n,
                    );
                  },
                  childCount: _collectionService.allAnimals.length,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                l10n?.animalCollectionProgress ?? '收集進度',
                '${_collectionService.collectedCount}/${_collectionService.totalAnimals}',
                Icons.pets,
              ),
              _buildStatItem(
                l10n?.animalCollectionTotalCheckIns ?? '總打卡天數',
                '${_checkedDates.length}',
                Icons.calendar_today,
              ),
              _buildStatItem(
                l10n?.animalCollectionConsecutiveStreak ?? '連續打卡',
                '$_consecutiveDays${l10n?.animalCollectionDaysUnit ?? '天'}',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _collectionService.collectionProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 動物卡片元件
class _AnimalCard extends StatefulWidget {
  final AnimalCollection animal;
  final bool isUnlocked;
  final int currentDays;
  final AppLocalizations? l10n;

  const _AnimalCard({
    super.key,
    required this.animal,
    required this.isUnlocked,
    required this.currentDays,
    required this.l10n,
  });

  @override
  State<_AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<_AnimalCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_AnimalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isUnlocked && widget.isUnlocked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.currentDays / widget.animal.requiredCheckInDays).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _controller.isAnimating ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6 * (1.0 - _controller.value)),
                  blurRadius: 20 * (1.0 - _controller.value),
                  spreadRadius: 5 * (1.0 - _controller.value),
                )
              ] : null,
            ),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: widget.isUnlocked ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.isUnlocked ? Colors.amber : Colors.grey[300]!,
            width: widget.isUnlocked ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showAnimalDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 動物圖片
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12), // 減少內邊距
                  child: _buildAnimalImage(),
                ),
              ),

              // 動物名稱
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: widget.isUnlocked
                    ? () {
                        final fullName = getAnimalName(widget.animal.id, widget.l10n);
                        final nameParts = splitAnimalName(fullName);
                        final hasBothNames = nameParts[1].isNotEmpty;
                        
                        return Column(
                          children: [
                            // 中文名稱
                            Text(
                              hasBothNames ? nameParts[0] : fullName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // 英文名稱（使用 FittedBox 自動縮放）
                            if (hasBothNames)
                              SizedBox(
                                height: 16,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    nameParts[1],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }()
                    : Text(
                        widget.l10n?.animalUnknown ?? '???',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),

              const SizedBox(height: 6),

              // 解鎖狀態或進度
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: widget.isUnlocked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[600], size: 14),
                          const SizedBox(width: 3),
                          Text(
                            widget.l10n?.animalCollectionCollected ?? '已收集',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            '${widget.l10n?.animalCollectionNeedDays ?? '需'}${widget.animal.requiredCheckInDays}${widget.l10n?.animalCollectionRequireDays ?? '天'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[400]!,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalImage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: widget.isUnlocked
          ? Image.asset(
              widget.animal.assetPath,
              key: ValueKey('${widget.animal.id}_unlocked'),
              fit: BoxFit.contain,
            )
          : ColorFiltered(
              key: ValueKey('${widget.animal.id}_locked'),
              colorFilter: const ColorFilter.mode(
                Color(0xFFBDBDBD), // 淺灰色
                BlendMode.srcATop,
              ),
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  widget.animal.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
    );
  }

  void _showAnimalDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              widget.isUnlocked ? Icons.pets : Icons.lock,
              color: widget.isUnlocked ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: widget.isUnlocked
                  ? () {
                      final fullName = getAnimalName(widget.animal.id, widget.l10n);
                      final nameParts = splitAnimalName(fullName);
                      final hasBothNames = nameParts[1].isNotEmpty;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasBothNames ? nameParts[0] : fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasBothNames)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                nameParts[1],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      );
                    }()
                  : Text(
                      widget.l10n?.animalUnknown ?? '???',
                      style: const TextStyle(fontSize: 20),
                    ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 動物圖片
            Center(
              child: SizedBox(
                height: 150,
                child: _buildAnimalImage(),
              ),
            ),
            const SizedBox(height: 20),

            // 詳細資訊
            if (widget.isUnlocked) ...[
              _buildInfoRow(Icons.verified, widget.l10n?.animalStatus ?? '狀態', widget.l10n?.animalUnlockedValue ?? '已解鎖', Colors.green),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.calendar_today,
                  widget.l10n?.animalUnlockDate ?? '取得日期',
                  widget.animal.unlockedAt != null
                      ? _formatDate(widget.animal.unlockedAt!)
                      : '未知',
                  Colors.blue),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, widget.l10n?.animalUnlockCondition ?? '解鎖條件',
                  widget.l10n?.animalCheckInDays.replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '打卡 ${widget.animal.requiredCheckInDays} 天', Colors.orange),
              const SizedBox(height: 12),
              // 命名理由
              _buildReasonSection(widget.animal.id, widget.l10n),
            ] else ...[
              _buildInfoRow(Icons.lock, widget.l10n?.animalStatus ?? '狀態', widget.l10n?.animalLockedValue ?? '未解鎖', Colors.grey),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, widget.l10n?.animalUnlockCondition ?? '解鎖條件',
                  widget.l10n?.animalCheckInDays.replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '打卡 ${widget.animal.requiredCheckInDays} 天', Colors.orange),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.show_chart,
                  widget.l10n?.animalCurrentProgress ?? '目前進度',
                  widget.l10n?.animalProgressDays.replaceFirst('%d', '${widget.currentDays}').replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '${widget.currentDays} / ${widget.animal.requiredCheckInDays} 天',
                  Colors.blue),
              const SizedBox(height: 12),
              // 進度條
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (widget.currentDays / widget.animal.requiredCheckInDays)
                      .clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.l10n?.animalCollectionClose ?? '關閉'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    final hasValue = value.isNotEmpty;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        if (hasValue) ...[
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonSection(String animalId, AppLocalizations? l10n) {
    final reason = getAnimalReason(animalId, l10n);
    if (reason.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Colors.amber[700],
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n?.animalNameReason ?? '命名理由'}:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _MagicParticleOverlay extends StatefulWidget {
  final Offset startPosition;
  final Offset targetPosition;
  final VoidCallback onUnlock;
  final VoidCallback onComplete;

  const _MagicParticleOverlay({
    required this.startPosition,
    required this.targetPosition,
    required this.onUnlock,
    required this.onComplete,
  });

  @override
  State<_MagicParticleOverlay> createState() => _MagicParticleOverlayState();
}

class _MagicParticleOverlayState extends State<_MagicParticleOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _burstController;
  late Animation<double> _progressAnimation;
  
  // 隨機路徑控制點
  late List<Offset> _pathPoints;
  bool _isInitialized = false;
  bool _hasUnlocked = false;
  
  // 預先生成的拖尾粒子（優化：避免在 build 中創建）
  final List<_TrailParticle> _preGeneratedTrail = [];
  int _trailIndex = 0;
  
  // 預先生成的爆炸粒子
  late List<_BurstParticle> _burstParticles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // 加快飛行速度
      vsync: this,
    );

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 600), // 加快爆炸速度
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    // 預先生成拖尾粒子（避免在動畫中分配記憶體）
    for (int i = 0; i < 80; i++) {
      _preGeneratedTrail.add(_TrailParticle(Offset.zero));
    }
    
    // 預先生成爆炸粒子（增加數量讓效果更震撼）
    _burstParticles = List.generate(35, (_) => _BurstParticle(Offset.zero));

    _controller.addListener(_onAnimationUpdate);

    _burstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }
  
  bool _soundPlayed = false; // 音效是否已播放
  
  void _onAnimationUpdate() {
    // 當動畫接近 68% 時提前播放音效（在爆破前更早）
    if (_controller.value > 0.68 && !_soundPlayed) {
      _soundPlayed = true;
      SoundEffectService().playUnlockSound();
    }
    
    // 當動畫接近尾聲時觸發解鎖
    if (_controller.value > 0.95 && !_hasUnlocked) {
      _hasUnlocked = true;
      widget.onUnlock();
      
      // 更新爆炸粒子的初始位置
      final targetPos = widget.targetPosition;
      for (var p in _burstParticles) {
        p.initialPosition = targetPos;
      }
      _burstController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _generatePath(screenSize);
      _controller.forward();
      _isInitialized = true;
    }
  }
  
  void _generatePath(Size screenSize) {
    final random = Random();
    final start = widget.startPosition;
    final end = widget.targetPosition;
    
    const padding = 40.0;
    double clampX(double x) => x.clamp(padding, screenSize.width - padding);
    double clampY(double y) => y.clamp(padding, screenSize.height - padding);
    
    final rangeX = screenSize.width * 0.4;
    final rangeY = screenSize.height * 0.4;
    
    final p1 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.25 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.25 + (random.nextDouble() - 0.5) * rangeY),
    );

    final p2 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.50 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.50 + (random.nextDouble() - 0.5) * rangeY),
    );

    final p3 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.75 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.75 + (random.nextDouble() - 0.5) * rangeY),
    );
    
    _pathPoints = [start, p1, p2, p3, end];
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationUpdate);
    _controller.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 CustomPaint 取代 Stack + Positioned，大幅提升效能
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _burstController]),
        builder: (context, child) {
          final t = _progressAnimation.value;
          final currentPos = _calculateBezierPoint(t, _pathPoints);
          
          // 更新拖尾位置（重用現有物件）
          if (!_hasUnlocked && _trailIndex < _preGeneratedTrail.length) {
            _preGeneratedTrail[_trailIndex].position = currentPos;
            _trailIndex++;
          }
          
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _MagicParticlePainter(
              progress: t,
              burstProgress: _burstController.value,
              currentPosition: currentPos,
              trail: _preGeneratedTrail.sublist(0, _trailIndex),
              burstParticles: _hasUnlocked ? _burstParticles : [],
              hasUnlocked: _hasUnlocked,
            ),
          );
        },
      ),
    );
  }
  
  Offset _calculateBezierPoint(double t, List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    
    List<Offset> tempPoints = List.from(points);
    int n = tempPoints.length - 1;
    
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n - i; j++) {
        tempPoints[j] = Offset(
          (1 - t) * tempPoints[j].dx + t * tempPoints[j + 1].dx,
          (1 - t) * tempPoints[j].dy + t * tempPoints[j + 1].dy,
        );
      }
    }
    return tempPoints[0];
  }
}

/// 使用 CustomPainter 繪製粒子效果（比 Stack + Container 高效得多）
class _MagicParticlePainter extends CustomPainter {
  final double progress;
  final double burstProgress;
  final Offset currentPosition;
  final List<_TrailParticle> trail;
  final List<_BurstParticle> burstParticles;
  final bool hasUnlocked;
  
  _MagicParticlePainter({
    required this.progress,
    required this.burstProgress,
    required this.currentPosition,
    required this.trail,
    required this.burstParticles,
    required this.hasUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製拖尾光暈（外層）
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fadeMultiplier = (1.0 - burstProgress).clamp(0.0, 1.0);
    
    for (int i = 0; i < trail.length; i++) {
      final particle = trail[i];
      final opacity = ((i + 1) / trail.length * fadeMultiplier).clamp(0.0, 1.0);
      
      // 繪製外層光暈
      glowPaint.color = particle.color.withOpacity(opacity * 0.4);
      canvas.drawCircle(
        particle.position + particle.jitter,
        particle.size * 0.8,
        glowPaint,
      );
    }
    
    // 繪製拖尾核心（內層，更亮）
    final trailPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < trail.length; i++) {
      final particle = trail[i];
      final opacity = ((i + 1) / trail.length * fadeMultiplier).clamp(0.0, 1.0);
      
      trailPaint.color = particle.color.withOpacity(opacity);
      canvas.drawCircle(
        particle.position + particle.jitter,
        particle.size / 2,
        trailPaint,
      );
    }
    
    // 繪製爆炸粒子
    if (hasUnlocked) {
      // 繪製中央閃光
      if (burstProgress < 0.3) {
        final flashOpacity = (1.0 - burstProgress / 0.3).clamp(0.0, 1.0);
        final flashPaint = Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
        flashPaint.color = Colors.white.withOpacity(flashOpacity * 0.8);
        canvas.drawCircle(burstParticles.isNotEmpty ? burstParticles.first.initialPosition : Offset.zero, 50 * (1.0 - burstProgress), flashPaint);
      }
      
      // 繪製爆炸粒子外層光暈
      final burstGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final burstOpacity = (1.0 - burstProgress).clamp(0.0, 1.0);
      final burstScale = 1.0 - burstProgress * 0.3;
      
      for (var p in burstParticles) {
        final pos = Offset(
          p.initialPosition.dx + p.velocity.dx * burstProgress * 180,
          p.initialPosition.dy + p.velocity.dy * burstProgress * 180 + (60 * burstProgress * burstProgress),
        );
        
        // 外層光暈
        burstGlowPaint.color = p.color.withOpacity(burstOpacity * 0.5);
        canvas.drawCircle(pos, p.size * burstScale, burstGlowPaint);
      }
      
      // 繪製爆炸粒子核心
      final burstPaint = Paint()..style = PaintingStyle.fill;
      for (var p in burstParticles) {
        final pos = Offset(
          p.initialPosition.dx + p.velocity.dx * burstProgress * 180,
          p.initialPosition.dy + p.velocity.dy * burstProgress * 180 + (60 * burstProgress * burstProgress),
        );
        
        burstPaint.color = p.color.withOpacity(burstOpacity);
        canvas.drawCircle(pos, p.size / 2 * burstScale, burstPaint);
      }
    }
    
    // 繪製主體星星
    if (!hasUnlocked) {
      _drawMainStar(canvas, currentPosition, progress);
    }
  }
  
  void _drawMainStar(Canvas canvas, Offset position, double t) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(t * 6 * pi);
    
    // 繪製外層大光暈（更明顯）
    final outerGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    outerGlowPaint.color = Colors.amber.withOpacity(0.6);
    canvas.drawCircle(Offset.zero, 35, outerGlowPaint);
    
    // 繪製內層光暈
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.yellow.withOpacity(0.9),
          Colors.orange.withOpacity(0.0),
        ],
        stops: const [0.2, 0.5, 1.0],
      ).createShader(const Rect.fromLTWH(-30, -30, 60, 60));
    
    canvas.drawCircle(Offset.zero, 30, glowPaint);
    
    // 繪製星星圖標（稍大一點）
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    _drawStar(canvas, Offset.zero, 14, 7, 5, starPaint);
    
    canvas.restore();
  }
  
  void _drawStar(Canvas canvas, Offset center, double outerRadius, double innerRadius, int points, Paint paint) {
    final path = Path();
    final angle = pi / points;
    
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + r * cos(i * angle - pi / 2);
      final y = center.dy + r * sin(i * angle - pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MagicParticlePainter oldDelegate) {
    return progress != oldDelegate.progress || 
           burstProgress != oldDelegate.burstProgress;
  }
}

class _BurstParticle {
  Offset initialPosition;
  final Offset velocity;
  final double size;
  final Color color;
  
  _BurstParticle(this.initialPosition) 
    : velocity = Offset.fromDirection(Random().nextDouble() * 2 * pi, 0.6 + Random().nextDouble() * 1.8),
      size = 6.0 + Random().nextDouble() * 10.0,
      color = [
        Colors.amber,
        Colors.yellow,
        Colors.orangeAccent,
        Colors.yellowAccent,
        Colors.white,
      ][Random().nextInt(5)];
}

class _TrailParticle {
  Offset position;
  final Offset jitter;
  final double size;
  final Color color;
  
  _TrailParticle(this.position) 
    : jitter = Offset((Random().nextDouble() - 0.5) * 20, (Random().nextDouble() - 0.5) * 20),
      size = 5.0 + Random().nextDouble() * 6.0,
      color = [
        Colors.amber,
        Colors.yellow,
        Colors.orangeAccent,
        Colors.yellowAccent,
        Colors.white,
      ][Random().nextInt(5)];
}
