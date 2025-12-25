/// 簡單的 LRU (Least Recently Used) 快取實作
/// 
/// 用於限制快取大小，自動移除最久未使用的項目
class LruCache<K, V> {
  final int _maxSize;
  final Map<K, V> _cache = {};
  final List<K> _accessOrder = [];

  LruCache({required int maxSize}) : _maxSize = maxSize;

  /// 取得快取值
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // 更新存取順序
    _accessOrder.remove(key);
    _accessOrder.add(key);
    
    return _cache[key];
  }

  /// 設定快取值
  void put(K key, V value) {
    // 如果已存在，先移除
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }
    
    // 如果超過上限，移除最舊的項目
    if (_cache.length >= _maxSize && !_cache.containsKey(key)) {
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
    
    _cache[key] = value;
    _accessOrder.add(key);
  }

  /// 檢查是否包含 key
  bool containsKey(K key) => _cache.containsKey(key);

  /// 清空快取
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// 取得目前快取大小
  int get length => _cache.length;

  /// 取得快取上限
  int get maxSize => _maxSize;
}
