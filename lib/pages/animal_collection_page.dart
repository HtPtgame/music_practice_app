import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_collection.dart';
import '../services/auth_service_config.dart';
import '../services/user_data_sync_service.dart';
import '../widgets/unlock_animation_dialog.dart';

/// 動物圖鑑頁面
class AnimalCollectionPage extends StatefulWidget {
  const AnimalCollectionPage({super.key});

  @override
  State<AnimalCollectionPage> createState() => _AnimalCollectionPageState();
}

class _AnimalCollectionPageState extends State<AnimalCollectionPage> {
  late AnimalCollectionService _collectionService;
  final UserDataSyncService _syncService = UserDataSyncService();
  bool _isLoading = true;

  // 使用首頁的打卡數據
  Set<String> _checkedDates = {};
  int _consecutiveDays = 0;

  @override
  void initState() {
    super.initState();
    _collectionService = AnimalCollectionService();
    _loadData();
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

      // 記錄舊的解鎖數量
      final oldUnlockedCount = _collectionService.collectedCount;

      setState(() {
        _checkedDates = checkedDatesJson.toSet();
        _consecutiveDays = consecutiveDays;
        // 根據打卡天數解鎖動物
        _collectionService.checkAndUnlockAnimals(_checkedDates.length);
        _isLoading = false;
      });

      // 檢查是否有新解鎖的動物
      final newUnlockedCount = _collectionService.collectedCount;
      if (newUnlockedCount > oldUnlockedCount) {
        // 獲得新動物，顯示慶祝動畫
        final newAnimals = _collectionService.unlockedAnimals
            .skip(oldUnlockedCount)
            .toList();
        
        // 等待畫面渲染完成後顯示動畫
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var animal in newAnimals) {
            _showUnlockAnimation(animal);
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

  /// 顯示解鎖動物的慶祝動畫
  void _showUnlockAnimation(AnimalCollection animal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnlockAnimationDialog(animal: animal),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            '動物圖鑑',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
          title: const Text(
            '動物圖鑑',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[400], // 與下方統計卡片統一
        ),
        body: CustomScrollView(
          slivers: [
            // 統計資訊卡片（可滑動）
            SliverToBoxAdapter(
              child: _buildStatsCard(),
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
                    final isUnlocked = status.isUnlocked;
                    final totalDays = _checkedDates.length;

                    return _AnimalCard(
                      animal: status, // ✅ 使用 status（含 unlockedAt）而不是 animal
                      isUnlocked: isUnlocked,
                      currentDays: totalDays,
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

  Widget _buildStatsCard() {
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
                '收集進度',
                '${_collectionService.collectedCount}/${_collectionService.totalAnimals}',
                Icons.pets,
              ),
              _buildStatItem(
                '總打卡天數',
                '${_checkedDates.length}',
                Icons.calendar_today,
              ),
              _buildStatItem(
                '連續打卡',
                '${_consecutiveDays}天',
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
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 動物卡片元件
class _AnimalCard extends StatelessWidget {
  final AnimalCollection animal;
  final bool isUnlocked;
  final int currentDays;

  const _AnimalCard({
    required this.animal,
    required this.isUnlocked,
    required this.currentDays,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentDays / animal.requiredCheckInDays).clamp(0.0, 1.0);

    return Card(
      elevation: isUnlocked ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked ? Colors.amber : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
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
                isUnlocked ? animal.name : '???',
                style: TextStyle(
                  fontSize: 13, // 縮小字體
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black87 : Colors.grey,
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
              child: isUnlocked
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[600], size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '已收集',
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
                          '需${animal.requiredCheckInDays}天',
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
    );
  }

  Widget _buildAnimalImage() {
    if (isUnlocked) {
      return Image.asset(
        animal.assetPath,
        fit: BoxFit.contain,
      );
    } else {
      // 未解鎖：整個圖片變成淺灰色
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFFBDBDBD), // 淺灰色
          BlendMode.srcATop,
        ),
        child: Opacity(
          opacity: 0.5,
          child: Image.asset(
            animal.assetPath,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
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
              isUnlocked ? Icons.pets : Icons.lock,
              color: isUnlocked ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isUnlocked ? animal.name : '???',
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
            if (isUnlocked) ...[
              _buildInfoRow(Icons.verified, '狀態', '已解鎖', Colors.green),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.calendar_today,
                  '取得日期',
                  animal.unlockedAt != null
                      ? _formatDate(animal.unlockedAt!)
                      : '未知',
                  Colors.blue),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, '解鎖條件',
                  '打卡 ${animal.requiredCheckInDays} 天', Colors.orange),
            ] else ...[
              _buildInfoRow(Icons.lock, '狀態', '未解鎖', Colors.grey),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, '解鎖條件',
                  '打卡 ${animal.requiredCheckInDays} 天', Colors.orange),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.show_chart,
                  '目前進度',
                  '$currentDays / ${animal.requiredCheckInDays} 天',
                  Colors.blue),
              const SizedBox(height: 12),
              // 進度條
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentDays / animal.requiredCheckInDays)
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
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
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
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
