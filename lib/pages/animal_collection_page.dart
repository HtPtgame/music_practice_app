import 'package:flutter/material.dart';
import '../models/animal_collection.dart';
import '../services/check_in_service.dart';

/// 動物圖鑑頁面
class AnimalCollectionPage extends StatefulWidget {
  const AnimalCollectionPage({super.key});

  @override
  State<AnimalCollectionPage> createState() => _AnimalCollectionPageState();
}

class _AnimalCollectionPageState extends State<AnimalCollectionPage> {
  late AnimalCollectionService _collectionService;
  late CheckInService _checkInService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _collectionService = AnimalCollectionService();
    _checkInService = CheckInService();
    _loadData();
  }

  Future<void> _loadData() async {
    await _checkInService.loadCheckInData();
    // 根據打卡天數解鎖動物
    _collectionService.checkAndUnlockAnimals(_checkInService.totalCheckInDays);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('動物圖鑑'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('動物圖鑑'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // 統計資訊卡片
          _buildStatsCard(),
          
          // 動物卡片網格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 改成3列以容納更多動物
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75, // 稍微調整比例
              ),
              itemCount: _collectionService.allAnimals.length,
              itemBuilder: (context, index) {
                final animal = _collectionService.allAnimals[index];
                final status = _collectionService.getAnimalStatus(animal.id);
                final isUnlocked = status.isUnlocked;
                final totalDays = _checkInService.totalCheckInDays;
                
                return _AnimalCard(
                  animal: animal,
                  isUnlocked: isUnlocked,
                  currentDays: totalDays,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCheckIn,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.check_circle),
        label: Text(
          _checkInService.hasCheckedInToday ? '今天已打卡' : '打卡',
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    final success = await _checkInService.checkIn();
    
    if (success) {
      // 重新檢查解鎖狀態
      _collectionService.checkAndUnlockAnimals(_checkInService.totalCheckInDays);
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打卡成功！連續打卡 ${_checkInService.currentStreak} 天'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今天已經打卡過了！'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
                '${_checkInService.totalCheckInDays}',
                Icons.calendar_today,
              ),
              _buildStatItem(
                '連續打卡',
                '${_checkInService.currentStreak}天',
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
    final daysNeeded = animal.requiredCheckInDays - currentDays;
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
                        Icon(Icons.check_circle, color: Colors.green[600], size: 14),
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
                          daysNeeded > 0
                              ? '需$daysNeeded天'
                              : '即將解鎖!',
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
    return isUnlocked
        ? Image.asset(
            animal.assetPath,
            fit: BoxFit.contain,
          )
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0, // Red channel
              0.2126, 0.7152, 0.0722, 0, 0, // Green channel
              0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
              0,      0,      0,      1, 0, // Alpha channel
            ]),
            child: Image.asset(
              animal.assetPath,
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.3),
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
              isUnlocked ? Icons.pets : Icons.lock,
              color: isUnlocked ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(isUnlocked ? animal.name : '未解鎖'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: _buildAnimalImage(),
            ),
            const SizedBox(height: 16),
            if (!isUnlocked) ...[
              Text(
                '需要打卡 ${animal.requiredCheckInDays} 天才能解鎖',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '目前進度: $currentDays / ${animal.requiredCheckInDays} 天',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Text(
                '解鎖時間: ${_formatDate(animal.unlockedAt!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
