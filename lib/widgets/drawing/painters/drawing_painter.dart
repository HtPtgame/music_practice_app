import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../models/drawing_data.dart';
import '../managers/brush_texture_pool.dart';

/// 🎨 繪圖畫筆 (CustomPainter)
/// 
/// Phase 3 重構: 從 DrawingCanvas 提取
/// 負責所有筆劃的渲染，包括紋理筆刷、橡皮擦等
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;
  final BrushTexturePool? texturePool;
  final bool isPoolReady;
  final ui.Image? cachedBackground;
  final ui.Image? currentStrokeCache;
  final int currentStrokeCachedPoints;

  // Paint 緩存
  final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
    this.texturePool,
    this.isPoolReady = false,
    this.cachedBackground,
    this.currentStrokeCache,
    this.currentStrokeCachedPoints = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🚀 優先使用快取背景（已完成的筆劃）
    if (cachedBackground != null) {
      canvas.drawImage(cachedBackground!, Offset.zero, Paint());
    } else {
      // 沒有快取時，渲染所有已完成的筆劃
      for (final stroke in strokes) {
        drawTextureBrush(
            canvas, stroke.points, stroke.color, stroke.strokeWidth,
            useSkipping: true);
      }
    }

    // 🎨 渲染當前正在繪製的筆劃（使用增量快取）
    if (currentStroke.isNotEmpty) {
      if (isErasing) {
        // 🧹 橡皮擦：使用簡單原始筆刷
        _drawSimpleBrush(
            canvas, currentStroke, currentColor, currentStrokeWidth);
      } else {
        // 🎨 一般繪圖：使用增量快取
        if (currentStrokeCache != null && currentStrokeCachedPoints > 0) {
          canvas.drawImage(currentStrokeCache!, Offset.zero, Paint());

          // 只渲染新增的點（從快取點數開始）
          if (currentStroke.length > currentStrokeCachedPoints) {
            final newPoints = currentStroke.sublist(currentStrokeCachedPoints);
            drawTextureBrush(
                canvas, newPoints, currentColor, currentStrokeWidth,
                useSkipping: false);
          }
        } else {
          // 沒有快取時，渲染所有點
          drawTextureBrush(
              canvas, currentStroke, currentColor, currentStrokeWidth,
              useSkipping: false);
        }
      }
    }
  }

  /// 🎨 將單一筆劃繪製到 Canvas (供外部快取使用)
  void drawStrokeToCanvas(Canvas canvas, DrawingStroke stroke) {
    // ✨ 使用和即時繪製完全相同的渲染路徑
    // 使用完整8層渲染（確保顏色正確）
    _drawFullTextureBrush(
      canvas,
      stroke.points,
      stroke.color,
      stroke.strokeWidth,
      useSkipping: true,
    );
  }

  /// 完整筆劃渲染 (用於已完成的筆劃)
  void drawTextureBrush(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth,
      {bool useSkipping = true}) {
    if (points.isEmpty) return;

    // 🎯 智能跳點策略 - 平衡質量與性能
    int pointStep = 1; // 預設不跳點

    if (useSkipping) {
      // 只有已完成的筆劃才使用跳點優化
      if (points.length <= 20) {
        pointStep = 1; // 短筆劃：全部渲染
      } else if (points.length <= 80) {
        pointStep = 2; // 中等筆劃：跳1點
      } else {
        pointStep = 3; // 長筆劃：跳2點
      }
    }

    for (int i = 0; i < points.length; i += pointStep) {
      // 🚀 使用紋理池優化渲染
      if (isPoolReady && texturePool != null) {
        _drawStampFromPool(canvas, points[i], strokeWidth, i);
      } else {
        // 降級方案：使用簡化渲染（當前筆劃）或完整渲染（已完成筆劃）
        if (!useSkipping) {
          // 當前筆劃：使用快速簡化版本
          _drawQuickStamp(canvas, points[i], color, strokeWidth);
        } else {
          // 已完成筆劃：使用完整8層渲染
          _drawFullStampAtPoint(canvas, points[i], color, strokeWidth, i);
        }
      }
    }
  }

  /// 完整8層紋理筆劃渲染（私有）
  void _drawFullTextureBrush(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth,
      {bool useSkipping = true}) {
    if (points.isEmpty) return;

    int pointStep = 1;
    if (useSkipping) {
      if (points.length <= 20) {
        pointStep = 1;
      } else if (points.length <= 80) {
        pointStep = 2;
      } else {
        pointStep = 3;
      }
    }

    for (int i = 0; i < points.length; i += pointStep) {
      _drawFullStampAtPoint(canvas, points[i], color, strokeWidth, i);
    }
  }

  /// 🎯 完整8層肌理渲染 - 確定性算法（無隨機數）
  void _drawFullStampAtPoint(Canvas canvas, Offset point, Color color,
      double strokeWidth, int pointIndex) {
    // ✨ 確定性偽隨機數生成器 - 基於座標和索引
    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   pointIndex * 83492791 ^ 
                   seedCounter;
      seedCounter++;
      return _deterministicRandom(seed);
    }
    
    int nextInt(int max) {
      return (nextRandom() * max).floor();
    }

    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (nextRandom() - 0.5) * variation;
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }

    // 第0層: 紙張纖維紋理 (8-12條)
    final fiberCount = 8 + nextInt(5);
    for (int j = 0; j < fiberCount; j++) {
      final baseAngle = nextRandom() * 2 * math.pi;
      final angleVariation = (nextRandom() - 0.5) * 0.4;
      final fiberAngle = baseAngle + angleVariation;
      final fiberLength = strokeWidth * (0.6 + nextRandom() * 0.9);
      final fiberThickness = strokeWidth * 0.05 * (0.5 + nextRandom());
      final startOffsetX = (nextRandom() - 0.5) * strokeWidth * 1.2;
      final startOffsetY = (nextRandom() - 0.5) * strokeWidth * 1.2;
      final startPoint =
          Offset(point.dx + startOffsetX, point.dy + startOffsetY);
      final endPoint = Offset(
        startPoint.dx + math.cos(fiberAngle) * fiberLength,
        startPoint.dy + math.sin(fiberAngle) * fiberLength,
      );
      final fiberColor = getHueVariation(color, 15);
      _paintCache
        ..color = fiberColor.withValues(alpha: 0.02 + nextRandom() * 0.04)
        ..strokeWidth = fiberThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPoint, endPoint, _paintCache);
    }

    // 第1層: 底層擴散 (12-20個點)
    final spreadCount = 12 + nextInt(9);
    for (int i = 0; i < spreadCount; i++) {
      final angleBase = nextRandom() * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.8;
      final angle = angleBase + angleNoise;
      final distFactor1 = math.pow(nextRandom(), 0.4).toDouble();
      final distFactor2 = nextRandom();
      final distFactor = (distFactor1 * 0.7 + distFactor2 * 0.3);
      final maxDistance = strokeWidth * (2.2 + nextRandom() * 1.4);
      final distance = distFactor * maxDistance;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final opacity = 0.03 + (1 - distFactor) * 0.12;
      final dotSize = strokeWidth * (0.25 + nextRandom() * 0.45);
      final dotColor = getHueVariation(color, 10);
      _paintCache.color = dotColor.withValues(alpha: opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY), dotSize, _paintCache);
    }

    // 第2層: 顆粒層 (8-16個點)
    final particleCount = 8 + nextInt(9);
    for (int i = 0; i < particleCount; i++) {
      final offsetX =
          (math.pow(nextRandom(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final offsetY =
          (math.pow(nextRandom(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final opacity = 0.12 + nextRandom() * 0.32;
      final sizeVariation = nextRandom();
      final particleSize =
          strokeWidth * (0.2 + math.pow(sizeVariation, 0.7) * 0.6);
      final particleColor = getHueVariation(color, 12);
      _paintCache.color = particleColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          particleSize, _paintCache);
    }

    // 第3層: 刮擦紋理 (2-4條刮痕)
    if (pointIndex > 0) {
      final scratchCount = 2 + nextInt(3);
      for (int j = 0; j < scratchCount; j++) {
        final angle = nextRandom() * 2 * math.pi;
        final offset = (j - scratchCount / 2) * strokeWidth * 0.3;
        final perpAngle = angle + math.pi / 2;
        final offsetX = math.cos(perpAngle) * offset;
        final offsetY = math.sin(perpAngle) * offset;
        final scratchLength = strokeWidth * (0.5 + nextRandom() * 0.5);
        final scratchOpacity = 0.08 + nextRandom() * 0.15;
        final scratchWidth = strokeWidth * (0.1 + nextRandom() * 0.15);
        final scratchColor = getHueVariation(color, 8);
        final p1 = Offset(point.dx + offsetX, point.dy + offsetY);
        final p2 = Offset(p1.dx + math.cos(angle) * scratchLength,
            p1.dy + math.sin(angle) * scratchLength);
        _paintCache
          ..color = scratchColor.withValues(alpha: scratchOpacity)
          ..strokeWidth = scratchWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, _paintCache);
      }
    }

    // 第4層: 厚塗堆積 (5-10個層)
    final layerCount = 5 + nextInt(6);
    for (int j = 0; j < layerCount; j++) {
      final clusterFactor = math.pow(nextRandom(), 0.5).toDouble();
      final offsetX =
          (nextRandom() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final offsetY =
          (nextRandom() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final opacity = 0.15 + nextRandom() * 0.35;
      final layerSize =
          strokeWidth * (0.3 + math.pow(nextRandom(), 0.6) * 0.5);
      final layerColor = getHueVariation(color, 10);
      _paintCache.color = layerColor.withValues(alpha: opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          layerSize, _paintCache);
    }

    // 第5層: 主體核心
    _paintCache.color = getHueVariation(color, 6).withValues(alpha: 0.55);
    canvas.drawCircle(point, strokeWidth * 0.5, _paintCache);

    // 第6層: 高光 (2-4個)
    final highlightCount = 2 + nextInt(3);
    for (int i = 0; i < highlightCount; i++) {
      final offsetX = (nextRandom() - 0.75) * strokeWidth * 0.5;
      final offsetY = (nextRandom() - 0.75) * strokeWidth * 0.5;
      final highlightSize = strokeWidth * (0.2 + nextRandom() * 0.2);
      final highlightColor = getHueVariation(color, 8);
      _paintCache.color =
          highlightColor.withValues(alpha: 0.35 + nextRandom() * 0.25);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          highlightSize, _paintCache);
    }

    // 第7層: 陰影 (1-3個)
    final shadowCount = 1 + nextInt(3);
    for (int j = 0; j < shadowCount; j++) {
      final shadowX = (nextRandom() + 0.15) * strokeWidth * 0.4;
      final shadowY = (nextRandom() + 0.15) * strokeWidth * 0.4;
      final shadowSize = strokeWidth * (0.15 + nextRandom() * 0.15);
      final shadowColor = getHueVariation(color, 8);
      _paintCache.color =
          shadowColor.withValues(alpha: 0.15 + nextRandom() * 0.12);
      canvas.drawCircle(Offset(point.dx + shadowX, point.dy + shadowY),
          shadowSize, _paintCache);
    }

    // 第8層: 邊緣毛邊 (3-6個點)
    final edgeCount = 3 + nextInt(4);
    for (int i = 0; i < edgeCount; i++) {
      final angleBase = (i / edgeCount) * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.6;
      final angle = angleBase + angleNoise;
      final distanceVariation = 0.6 + nextRandom() * 1.2;
      final distance = strokeWidth * distanceVariation;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final edgeSize =
          strokeWidth * (0.08 + math.pow(nextRandom(), 0.7) * 0.25);
      final edgeOpacity = 0.08 + nextRandom() * 0.22;
      final edgeColor = getHueVariation(color, 12);
      _paintCache.color = edgeColor.withValues(alpha: edgeOpacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          edgeSize, _paintCache);
    }
  }

  /// ⚡ 快速簡化版 stamp - 用於即時顯示當前筆劃
  void _drawQuickStamp(
      Canvas canvas, Offset point, Color color, double strokeWidth) {
    // 只渲染核心 3 層，保證速度
    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   seedCounter;
      seedCounter++;
      return _deterministicRandom(seed);
    }

    // 第1層: 底層擴散（簡化）
    const diffusionCount = 6;
    for (int i = 0; i < diffusionCount; i++) {
      final angle = (i / diffusionCount) * 2 * math.pi;
      final distance = strokeWidth * (0.3 + nextRandom() * 0.5);
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final size = strokeWidth * 0.2;
      _paintCache.color = color.withValues(alpha: 0.1);
      canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY), size, _paintCache);
    }

    // 第2層: 主體核心
    _paintCache.color = color.withValues(alpha: 0.7);
    canvas.drawCircle(point, strokeWidth * 0.5, _paintCache);

    // 第3層: 高光
    _paintCache.color = color.withValues(alpha: 0.4);
    canvas.drawCircle(
        Offset(point.dx - strokeWidth * 0.15, point.dy - strokeWidth * 0.15),
        strokeWidth * 0.25,
        _paintCache);
  }

  /// 🧹 簡單原始筆刷 - 用於橡皮擦
  void _drawSimpleBrush(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (points.length == 1) {
      canvas.drawCircle(
          points[0], strokeWidth / 2, paint..style = PaintingStyle.fill);
    } else {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  /// 🚀 從紋理池繪製 stamp (O(1) 複雜度)
  void _drawStampFromPool(
      Canvas canvas, Offset point, double strokeWidth, int pointIndex) {
    if (texturePool == null || texturePool!.textures.isEmpty) return;
    
    // ✨ 確定性紋理選擇 - 基於座標和索引
    final textureIndex = (point.dx.toInt() * 73856093 ^ 
                         point.dy.toInt() * 19349663 ^ 
                         pointIndex * 83492791).abs() % texturePool!.textures.length;
    final texture = texturePool!.textures[textureIndex];

    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   pointIndex * 83492791 ^ 
                   seedCounter;
      seedCounter++;
      return _deterministicRandom(seed);
    }

    // 計算 stamp 實際大小
    final stampDisplaySize = strokeWidth * 4;

    canvas.save();

    // 移動到繪製點
    canvas.translate(point.dx, point.dy);

    // 🎨 輕微旋轉 (±8°)
    final rotation = (nextRandom() - 0.5) * 0.28;
    canvas.rotate(rotation);

    // 🎨 微縮放 (95%~105%)
    final scale = 0.95 + nextRandom() * 0.1;
    canvas.scale(scale);

    // 居中 stamp
    canvas.translate(-stampDisplaySize / 2, -stampDisplaySize / 2);

    // 繪製紋理
    final srcRect = Rect.fromLTWH(
        0, 0, texture.width.toDouble(), texture.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, stampDisplaySize, stampDisplaySize);

    canvas.drawImageRect(texture, srcRect, dstRect, _paintCache);

    canvas.restore();
  }

  /// 確定性偽隨機數生成
  static double _deterministicRandom(int seed) {
    final hash = ((seed * 2654435761) ^ (seed >> 16)) & 0x7FFFFFFF;
    return (hash % 10000) / 10000.0;
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth ||
        oldDelegate.cachedBackground != cachedBackground ||
        oldDelegate.currentStrokeCache != currentStrokeCache ||
        oldDelegate.currentStrokeCachedPoints != currentStrokeCachedPoints;
  }
}
