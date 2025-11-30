import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_collection.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import '../services/user_data_sync_service.dart';
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
    case 'cat': return l10n?.animalCat ?? '可愛貓咪';
    case 'dog': return l10n?.animalDog ?? '忠誠小狗';
    case 'fox': return l10n?.animalFox ?? '聰明狐狸';
    case 'panda': return l10n?.animalPanda ?? '萌萌熊貓';
    case 'rabbit': return l10n?.animalRabbit ?? '活潑兔子';
    case 'bear': return l10n?.animalBear ?? '可愛熊熊';
    case 'deer': return l10n?.animalDeer ?? '優雅小鹿';
    case 'penguin': return l10n?.animalPenguin ?? '企鵝寶寶';
    case 'koala': return l10n?.animalKoala ?? '無尾熊';
    case 'raccoon': return l10n?.animalRaccoon ?? '浣熊小可愛';
    case 'squirrel': return l10n?.animalSquirrel ?? '松鼠';
    case 'hedgehog': return l10n?.animalHedgehog ?? '刺蝟';
    case 'seal': return l10n?.animalSeal ?? '海豹';
    case 'sheep': return l10n?.animalSheep ?? '綿羊';
    case 'lion': return l10n?.animalLion ?? '獅子王';
    case 'kangaroo': return l10n?.animalKangaroo ?? '袋鼠';
    case 'sloth': return l10n?.animalSloth ?? '樹懶';
    case 'guinea_pig': return l10n?.animalGuineaPig ?? '天竺鼠';
    case 'prairie_dog': return l10n?.animalPrairieDog ?? '土撥鼠';
    case 'quokka': return l10n?.animalQuokka ?? '短尾矮袋鼠';
    case 'fairy': return l10n?.animalFairy ?? '小精靈';
    case 'taiwanbear': return l10n?.animalTaiwanBear ?? '台灣黑熊';
    default: return '???';
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
        // 根據打卡天數解鎖動物
        _collectionService.checkAndUnlockAnimals(_checkedDates.length);
        _isLoading = false;
      });

      // 檢查是否有新解鎖的動物
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
    
    if (user != null && user.unlockedAnimals.isNotEmpty) {
      // 從雲端數據載入
      debugPrint('🐾 從雲端載入: ${user.unlockedAnimals}');
      _collectionService.loadUnlockedAnimals(user.unlockedAnimals);
    } else {
      // 從本地 SharedPreferences 載入（訪客模式）
      final prefs = await SharedPreferences.getInstance();
      final unlockedJson = prefs.getString('unlocked_animals');
      debugPrint('🐾 本地數據: $unlockedJson');
      
      if (unlockedJson != null) {
        try {
          final Map<String, dynamic> decoded =
              Map<String, dynamic>.from(jsonDecode(unlockedJson));
          final Map<String, String> unlockedAnimals =
              decoded.map((key, value) => MapEntry(key, value as String));
          debugPrint('🐾 解析後: $unlockedAnimals');
          _collectionService.loadUnlockedAnimals(unlockedAnimals);
        } catch (e) {
          debugPrint('載入本地動物解鎖數據失敗: $e');
        }
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
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 統計資訊卡片(可滑動)
            SliverToBoxAdapter(
              child: _buildStatsCard(l10n),
            ),

            // 動物卡片網格
            SliverPadding(
              padding: const EdgeInsets.all(16),
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
                '${_consecutiveDays}${l10n?.animalCollectionDaysUnit ?? '天'}',
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
                child: Text(
                  widget.isUnlocked ? getAnimalName(widget.animal.id, widget.l10n) : (widget.l10n?.animalUnknown ?? '???'),
                  style: TextStyle(
                    fontSize: 13, // 縮小字體
                    fontWeight: FontWeight.bold,
                    color: widget.isUnlocked ? Colors.black87 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // 限制單行
                  overflow: TextOverflow.ellipsis, // 超出顯示省略號
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
              child: Text(
                widget.isUnlocked ? getAnimalName(widget.animal.id, widget.l10n) : (widget.l10n?.animalUnknown ?? '???'),
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
              _buildInfoRow(Icons.verified, '${widget.l10n?.animalStatusUnlocked ?? '狀態：已解鎖'}', '', Colors.green),
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
                  '${widget.l10n?.animalCheckInDays.replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '打卡 ${widget.animal.requiredCheckInDays} 天'}', Colors.orange),
            ] else ...[
              _buildInfoRow(Icons.lock, '${widget.l10n?.animalStatusLocked ?? '狀態：未解鎖'}', '', Colors.grey),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, widget.l10n?.animalUnlockCondition ?? '解鎖條件',
                  '${widget.l10n?.animalCheckInDays.replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '打卡 ${widget.animal.requiredCheckInDays} 天'}', Colors.orange),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.show_chart,
                  widget.l10n?.animalCurrentProgress ?? '目前進度',
                  '${widget.l10n?.animalProgressDays.replaceFirst('%d', '${widget.currentDays}').replaceFirst('%d', '${widget.animal.requiredCheckInDays}') ?? '${widget.currentDays} / ${widget.animal.requiredCheckInDays} 天'}',
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
  late AnimationController _burstController; // 新增爆炸動畫控制器
  late Animation<double> _progressAnimation;
  
  // 隨機路徑控制點
  late List<Offset> _pathPoints;
  bool _isInitialized = false;
  bool _hasUnlocked = false;
  
  // 亮粉拖尾
  final List<_TrailParticle> _trail = [];
  
  // 爆炸粒子
  final List<_BurstParticle> _burstParticles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // 稍微加快飛行速度
      vsync: this,
    );

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addListener(() {
      // 當動畫接近尾聲時觸發解鎖
      if (_controller.value > 0.95 && !_hasUnlocked) {
        _hasUnlocked = true;
        widget.onUnlock();
        _spawnBurst();
        _burstController.forward(); // 啟動爆炸動畫
      }
    });

    _burstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }
  
  void _spawnBurst() {
    for (int i = 0; i < 30; i++) { // 增加粒子數量
      _burstParticles.add(_BurstParticle(widget.targetPosition));
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
    // 生成隨機路徑
    final random = Random();
    
    final start = widget.startPosition;
    final end = widget.targetPosition;
    
    // 限制範圍函數
    final padding = 40.0; // 邊界保留距離
    double clampX(double x) => x.clamp(padding, screenSize.width - padding);
    double clampY(double y) => y.clamp(padding, screenSize.height - padding);
    
    // 隨機偏移量
    final rangeX = screenSize.width * 0.5;
    final rangeY = screenSize.height * 0.5;
    
    // 生成3個控制點以增加曲線複雜度 (Quartic Bezier)
    // P1
    final p1 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.25 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.25 + (random.nextDouble() - 0.5) * rangeY),
    );

    // P2
    final p2 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.50 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.50 + (random.nextDouble() - 0.5) * rangeY),
    );

    // P3
    final p3 = Offset(
      clampX(start.dx + (end.dx - start.dx) * 0.75 + (random.nextDouble() - 0.5) * rangeX),
      clampY(start.dy + (end.dy - start.dy) * 0.75 + (random.nextDouble() - 0.5) * rangeY),
    );
    
    _pathPoints = [start, p1, p2, p3, end];
  }

  @override
  void dispose() {
    _controller.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _burstController]),
      builder: (context, child) {
        final t = _progressAnimation.value;
        final burstT = _burstController.value;
        final currentPos = _calculateBezierPoint(t, _pathPoints);
        
        // 產生亮粉 (直到爆炸開始前)
        if (!_hasUnlocked) {
           // 每次增加粒子
           for(int i=0; i<2; i++) {
             _trail.add(_TrailParticle(currentPos));
           }
           // 限制數量
           if (_trail.length > 80) {
             _trail.removeRange(0, _trail.length - 80);
           }
        }
        
        return Stack(
          children: [
            // 繪製拖尾亮粉
            for (var i = 0; i < _trail.length; i++)
              Positioned(
                left: _trail[i].position.dx + _trail[i].jitter.dx,
                top: _trail[i].position.dy + _trail[i].jitter.dy,
                child: Opacity(
                  // 拖尾隨爆炸進度淡出，而不是隨飛行進度淡出
                  opacity: (i / _trail.length).clamp(0.0, 1.0) * (1.0 - burstT).clamp(0.0, 1.0),
                  child: Container(
                    width: _trail[i].size,
                    height: _trail[i].size,
                    decoration: BoxDecoration(
                      color: _trail[i].color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _trail[i].color.withOpacity(0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    ),
                  ),
                ),
              ),
              
            // 繪製爆炸粒子
            if (_hasUnlocked)
              for (var p in _burstParticles)
                Positioned(
                  left: p.initialPosition.dx + p.velocity.dx * burstT * 150, // 擴散半徑
                  top: p.initialPosition.dy + p.velocity.dy * burstT * 150 + (50 * burstT * burstT), // 加上重力效果
                  child: Opacity(
                    opacity: (1.0 - burstT).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 - burstT * 0.5, // 隨時間變小
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: p.color.withOpacity(0.8),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                      ),
                    ),
                  ),
                ),

            // 主體星星 (到達終點後消失)
            if (!_hasUnlocked)
              Positioned(
                left: currentPos.dx - 20,
                top: currentPos.dy - 20,
                child: Transform.rotate(
                  angle: t * 6 * pi, // 旋轉3圈
                  child: IgnorePointer(
                    child: _buildParticle(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Offset _calculateBezierPoint(double t, List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    
    // De Casteljau's algorithm for arbitrary number of points
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
  
  Widget _buildParticle() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            Colors.yellow.withOpacity(0.9),
            Colors.orange.withOpacity(0.0),
          ],
          stops: const [0.2, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.8),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.star, color: Colors.white, size: 24),
    );
  }
}

class _BurstParticle {
  final Offset initialPosition;
  final Offset velocity;
  final double size;
  final Color color;
  
  _BurstParticle(this.initialPosition) 
    : velocity = Offset.fromDirection(Random().nextDouble() * 2 * pi, 0.5 + Random().nextDouble() * 1.5),
      size = 4.0 + Random().nextDouble() * 8.0,
      color = [
        Colors.amber,
        Colors.yellowAccent,
        Colors.white,
      ][Random().nextInt(3)];
}

class _TrailParticle {
  final Offset position;
  final Offset jitter;
  final double size;
  final Color color;
  
  _TrailParticle(this.position) 
    : jitter = Offset((Random().nextDouble() - 0.5) * 20, (Random().nextDouble() - 0.5) * 20),
      size = 3.5 + Random().nextDouble() * 4.5,
      color = [
        Colors.amber,        // 深一點的黃色
        Colors.yellowAccent, // 原本的黃色
        Colors.yellow[100]!, // 淺黃
      ][Random().nextInt(3)];
}
