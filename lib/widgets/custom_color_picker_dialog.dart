import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// 自訂顏色選擇對話框
///
/// 提供 HSV 色盤、RGB 滑桿、以及最多 5 個自訂顏色的管理功能
/// 支援拖曳排序、刪除、新增顏色
class CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final List<Color> savedColors;
  final Function(List<Color>) onColorsSaved;
  final Function(Color) onColorSelected;

  const CustomColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.savedColors,
    required this.onColorsSaved,
    required this.onColorSelected,
  });

  @override
  State<CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late Color _currentColor;
  late HSVColor _hsvColor;
  late List<Color> _tempSavedColors;
  int? _selectedColorIndex; // 用於交換顏色的選中索引
  int? _editingColorIndex; // 用於追蹤正在編輯的顏色槽
  bool _isSortMode = false; // 排序模式開關

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hsvColor = HSVColor.fromColor(_currentColor);
    _editingColorIndex = 0; // 預設選取第一個顏色槽位
    
    // 預設的5種顏色
    final defaultColors = [
      const Color(0xFF000000), // 黑色
      const Color(0xFFFF0000), // 紅色
      const Color(0xFF0000FF), // 藍色
      const Color(0xFF00FF00), // 綠色
      const Color(0xFFFFFF00), // 黃色
    ];
    
    // 確保總是有5個顏色槽位
    if (widget.savedColors.isEmpty) {
      // 如果沒有儲存的顏色，使用預設顏色
      _tempSavedColors = List.from(defaultColors);
    } else {
      _tempSavedColors = List.from(widget.savedColors);
      while (_tempSavedColors.length < 5) {
        // 用預設顏色填充不足的槽位
        int index = _tempSavedColors.length;
        _tempSavedColors.add(index < defaultColors.length 
          ? defaultColors[index] 
          : Colors.grey.shade300);
      }
      if (_tempSavedColors.length > 5) {
        _tempSavedColors = _tempSavedColors.sublist(0, 5);
      }
    }
    
    // 預設使用第一個顏色槽位的顏色
    _currentColor = _tempSavedColors[0];
    _hsvColor = HSVColor.fromColor(_currentColor);
  }

  void _updateColor(Color color) {
    setState(() {
      _currentColor = color;
      _hsvColor = HSVColor.fromColor(color);
      // 如果正在編輯某個顏色槽，同步更新該槽位的顏色
      if (_editingColorIndex != null && !_isSortMode) {
        _tempSavedColors[_editingColorIndex!] = color;
      }
    });
  }

  void _swapColors(int index1, int index2) {
    setState(() {
      final temp = _tempSavedColors[index1];
      _tempSavedColors[index1] = _tempSavedColors[index2];
      _tempSavedColors[index2] = temp;
      _selectedColorIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: PopScope(
        canPop: false, // 防止返回鍵關閉對話框
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 750),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題列
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "🎨 自訂畫筆顏色",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // 1. 色盤與預覽區
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HSV 色盤
                  Expanded(
                    flex: 3,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _SimpleHSVColorPicker(
                        hsvColor: _hsvColor,
                        onChanged: (hsv) {
                          setState(() {
                            _hsvColor = hsv;
                            _currentColor = hsv.toColor();
                            // 如果正在編輯某個顏色槽，同步更新該槽位的顏色
                            if (_editingColorIndex != null && !_isSortMode) {
                              _tempSavedColors[_editingColorIndex!] =
                                  _currentColor;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 預覽色塊
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: _currentColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: _currentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}",
                          style: TextStyle(
                            color: AppColors.dynamicTextLight,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 24),

              // 2. RGB 滑桿區
              Text(
                "RGB 調整",
                style:
                    TextStyle(color: AppColors.dynamicTextDark, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildRGBSlider(
                "R",
                _currentColor.red,
                Colors.red,
                (val) => _updateColor(_currentColor.withRed(val)),
              ),
              _buildRGBSlider(
                "G",
                _currentColor.green,
                Colors.green,
                (val) => _updateColor(_currentColor.withGreen(val)),
              ),
              _buildRGBSlider(
                "B",
                _currentColor.blue,
                Colors.blue,
                (val) => _updateColor(_currentColor.withBlue(val)),
              ),
              const SizedBox(height: 8),
              _buildValueSlider(),

              const SizedBox(height: 24),
              const Divider(),

              // 3. 當前自訂顏色區 (固定5個)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "當前畫筆顏色",
                    style: TextStyle(
                        color: AppColors.dynamicTextDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (_selectedColorIndex != null && _isSortMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            "點擊其他顏色交換位置",
                            style: TextStyle(
                                color: AppColors.dynamicPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      // 排序按鈕
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isSortMode = !_isSortMode;
                            if (!_isSortMode) {
                              _selectedColorIndex = null;
                            }
                            _editingColorIndex = null; // 切換模式時清除編輯狀態
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isSortMode
                                ? AppColors.dynamicPrimary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.swap_vert,
                            size: 20,
                            color: _isSortMode
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                height: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dynamicCard.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < 5; i++)
                      _buildColorSlot(i, _tempSavedColors[i]),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 底部按鈕
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "取消",
                        style: TextStyle(color: AppColors.dynamicTextLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onColorsSaved(_tempSavedColors);
                        widget.onColorSelected(_currentColor);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("儲存並使用"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 構建 RGB 滑桿組件
  Widget _buildRGBSlider(
    String label,
    int value,
    Color activeColor,
    Function(int) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextLight,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 30,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: activeColor,
                thumbColor: activeColor,
                inactiveTrackColor: activeColor.withOpacity(0.2),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 255,
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            value.toString(),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// 構建明度滑桿組件
  Widget _buildValueSlider() {
    // 將 HSV 的 Value (0-1) 轉換為 0-100 的百分比顯示
    int valuePercent = (_hsvColor.value * 100).round();
    
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            "V",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextLight,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 30,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.grey.shade700,
                thumbColor: Colors.grey.shade700,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              child: Slider(
                value: _hsvColor.value,
                min: 0,
                max: 1,
                onChanged: (v) {
                  setState(() {
                    _hsvColor = _hsvColor.withValue(v);
                    _currentColor = _hsvColor.toColor();
                    // 如果正在編輯某個顏色槽，同步更新
                    if (_editingColorIndex != null) {
                      _tempSavedColors[_editingColorIndex!] = _currentColor;
                    }
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            "$valuePercent%",
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// 構建顏色槽位（支援點擊替換和排序交換）
  Widget _buildColorSlot(int index, Color color) {
    final bool isSelected = _selectedColorIndex == index;
    final bool isEditing = _editingColorIndex == index && !_isSortMode;
    // 檢查是否為空槽位（灰色）
    final bool isEmpty = color.value == Colors.grey.shade300.value;
    final bool isCurrentColor =
        (_currentColor.value == color.value || isEditing) && !isEmpty;
    final bool showSortIcon = _isSortMode &&
        (_selectedColorIndex == null || _selectedColorIndex != index);

    return GestureDetector(
      onTap: () {
        if (_isSortMode) {
          // 排序模式
          if (_selectedColorIndex == null) {
            // 第一次點擊：選中此顏色槽位
            setState(() {
              _selectedColorIndex = index;
            });
          } else if (_selectedColorIndex == index) {
            // 點擊同一個槽位：取消選擇
            setState(() {
              _selectedColorIndex = null;
            });
          } else {
            // 點擊其他槽位：交換顏色
            _swapColors(_selectedColorIndex!, index);
          }
        } else {
          // 正常模式：直接使用該顏色並進入編輯模式
          if (!isEmpty) {
            setState(() {
              _editingColorIndex = index;
              _currentColor = color;
              _hsvColor = HSVColor.fromColor(color);
            });
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.dynamicPrimary : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (isSelected)
                  BoxShadow(
                    color: AppColors.dynamicPrimary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            // 顯示當前正在編輯的顏色標記
            child: isCurrentColor && !isEmpty && !_isSortMode
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
          // 排序模式下未選中的顏色顯示排序圖標
          if (showSortIcon)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          // 選中狀態顯示藍色排序圖標
          if (isSelected && _isSortMode)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 簡單的 HSV 色盤實作
/// 使用極座標計算色相和飽和度
class _SimpleHSVColorPicker extends StatefulWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  const _SimpleHSVColorPicker({
    required this.hsvColor,
    required this.onChanged,
  });

  @override
  State<_SimpleHSVColorPicker> createState() => _SimpleHSVColorPickerState();
}

class _SimpleHSVColorPickerState extends State<_SimpleHSVColorPicker> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            _handleGesture(
              details.localPosition,
              constraints.maxWidth,
              constraints.maxHeight,
            );
          },
          onTapDown: (details) {
            _handleGesture(
              details.localPosition,
              constraints.maxWidth,
              constraints.maxHeight,
            );
          },
          child: ClipOval(
            child: Container(
              decoration: const BoxDecoration(
                gradient: SweepGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Color(0xFFFF00FF), // Magenta
                    Colors.red
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 飽和度遮罩 (由中心向外變深)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                  // 選擇指示器
                  Positioned(
                    left: _getOffset(constraints.maxWidth).dx - 10,
                    top: _getOffset(constraints.maxHeight).dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.hsvColor.toColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleGesture(Offset position, double width, double height) {
    // 圓形區域選擇，支援完整RGB範圍
    double centerX = width / 2;
    double centerY = height / 2;
    double dx = position.dx - centerX;
    double dy = position.dy - centerY;
    double angle = atan2(dy, dx);
    double dist = sqrt(dx * dx + dy * dy);
    double radius = width / 2;

    // 允許完整圓形區域，不限制距離
    if (dist > radius) dist = radius;

    // 計算 Hue (0-360)
    // 將角度轉換為0度在右側，順時針增加
    double hue = (angle * 180 / pi);
    if (hue < 0) hue += 360;

    // 計算 Saturation (0-1)
    double saturation = (dist / radius).clamp(0.0, 1.0);

    // 圓形色盤固定使用明度 1.0（100% 明度），這樣 RGB 才能達到 255
    // 圓形色盤的漸層繪製本身就是基於明度 100% 的假設
    widget.onChanged(
      HSVColor.fromAHSV(1.0, hue, saturation, 1.0),
    );
  }

  Offset _getOffset(double size) {
    // 將 HSV 轉回座標 (供顯示指示器) - 圓形區域
    double radius = size / 2;
    double dist = widget.hsvColor.saturation * radius;
    double angle = widget.hsvColor.hue * pi / 180;

    double dx = radius + dist * cos(angle);
    double dy = radius + dist * sin(angle);
    return Offset(dx, dy);
  }
}
