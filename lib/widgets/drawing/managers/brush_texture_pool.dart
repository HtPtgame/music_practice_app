import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🎨 筆刷紋理快取池
/// 
/// Phase 3 重構: 從 DrawingCanvas 提取
/// 預先生成多張紋理圖片，渲染時直接使用，達到 O(1) 複雜度
class BrushTexturePool {
  static const int _poolSize = 16; // 16 張紋理足夠隨機
  static const int _stampSize = 128; // 紋理圖片尺寸

  List<ui.Image> _textures = [];

  bool get isReady => _textures.length == _poolSize;
  List<ui.Image> get textures => _textures;

  /// 建立紋理池
  Future<void> buildPool(Color color, double strokeWidth) async {
    // 清除舊紋理
    _disposeTextures();
    _textures = [];

    // 建立 16 張不同的紋理
    final List<Future<ui.Image>> futures = [];
    for (int i = 0; i < _poolSize; i++) {
      futures.add(_createStamp(color, strokeWidth, i * 1000));
    }

    _textures = await Future.wait(futures);
  }

  /// 建立單一紋理 stamp
  Future<ui.Image> _createStamp(
      Color color, double strokeWidth, int seed) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(_stampSize / 2, _stampSize / 2);
    final scale = _stampSize / (strokeWidth * 4); // 縮放到合適大小

    // ✨ 確定性偽隨機數生成器
    int seedCounter = 0;
    double nextRandom() {
      final s = seed * 73856093 ^ seedCounter * 19349663;
      seedCounter++;
      return _deterministicRandom(s);
    }
    
    int nextInt(int max) {
      return (nextRandom() * max).floor();
    }

    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (nextRandom() - 0.5) * variation;
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }

    // 🎨 繪製 8 層肌理（整合到單一 stamp）

    // 第0層: 紙張纖維紋理
    final fiberCount = 8 + nextInt(5);
    for (int j = 0; j < fiberCount; j++) {
      final baseAngle = nextRandom() * 2 * math.pi;
      final angleVariation = (nextRandom() - 0.5) * 0.4;
      final fiberAngle = baseAngle + angleVariation;
      final fiberLength = strokeWidth * scale * (0.6 + nextRandom() * 0.9);
      final fiberThickness = strokeWidth * scale * 0.05 * (0.5 + nextRandom());
      final startOffsetX = (nextRandom() - 0.5) * strokeWidth * scale * 1.2;
      final startOffsetY = (nextRandom() - 0.5) * strokeWidth * scale * 1.2;
      final startPoint =
          Offset(center.dx + startOffsetX, center.dy + startOffsetY);
      final endPoint = Offset(
        startPoint.dx + math.cos(fiberAngle) * fiberLength,
        startPoint.dy + math.sin(fiberAngle) * fiberLength,
      );
      final fiberColor = getHueVariation(color, 15);
      paint
        ..color = fiberColor.withValues(alpha: 0.02 + nextRandom() * 0.04)
        ..strokeWidth = fiberThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPoint, endPoint, paint);
    }

    // 第1層: 底層擴散
    final spreadCount = 12 + nextInt(9);
    for (int i = 0; i < spreadCount; i++) {
      final angle = nextRandom() * 2 * math.pi;
      final distFactor = math.pow(nextRandom(), 0.4).toDouble();
      final maxDistance = strokeWidth * scale * (2.2 + nextRandom() * 1.4);
      final distance = distFactor * maxDistance;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final opacity = 0.03 + (1 - distFactor) * 0.12;
      final dotSize = strokeWidth * scale * (0.25 + nextRandom() * 0.45);
      final dotColor = getHueVariation(color, 10);
      paint.color = dotColor.withValues(alpha: opacity);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), dotSize, paint);
    }

    // 第2層: 顆粒層
    final particleCount = 8 + nextInt(9);
    for (int i = 0; i < particleCount; i++) {
      final offsetX = (nextRandom() - 0.5) * 2 * strokeWidth * scale * 1.6;
      final offsetY = (nextRandom() - 0.5) * 2 * strokeWidth * scale * 1.6;
      final opacity = 0.12 + nextRandom() * 0.32;
      final particleSize = strokeWidth * scale * (0.2 + math.pow(nextRandom(), 0.7) * 0.6);
      final particleColor = getHueVariation(color, 12);
      paint.color = particleColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(center.dx + offsetX, center.dy + offsetY),
          particleSize, paint);
    }

    // 第3層: 刮擦紋理
    final scratchCount = 2 + nextInt(3);
    for (int j = 0; j < scratchCount; j++) {
      final angle = nextRandom() * 2 * math.pi;
      final offset = (j - scratchCount / 2) * strokeWidth * scale * 0.3;
      final perpAngle = angle + math.pi / 2;
      final offsetX = math.cos(perpAngle) * offset;
      final offsetY = math.sin(perpAngle) * offset;
      final scratchLength = strokeWidth * scale * (0.5 + nextRandom() * 0.5);
      final scratchOpacity = 0.08 + nextRandom() * 0.15;
      final scratchWidth = strokeWidth * scale * (0.1 + nextRandom() * 0.15);
      final scratchColor = getHueVariation(color, 8);
      final p1 = Offset(center.dx + offsetX, center.dy + offsetY);
      final p2 = Offset(p1.dx + math.cos(angle) * scratchLength,
          p1.dy + math.sin(angle) * scratchLength);
      paint
        ..color = scratchColor.withValues(alpha: scratchOpacity)
        ..strokeWidth = scratchWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, paint);
    }

    // 第4層: 厚塗堆積
    final layerCount = 5 + nextInt(6);
    for (int j = 0; j < layerCount; j++) {
      final offsetX = (nextRandom() - 0.5) * strokeWidth * scale * 1.1;
      final offsetY = (nextRandom() - 0.5) * strokeWidth * scale * 1.1;
      final opacity = 0.15 + nextRandom() * 0.35;
      final layerSize = strokeWidth * scale * (0.3 + math.pow(nextRandom(), 0.6) * 0.5);
      final layerColor = getHueVariation(color, 10);
      paint.color = layerColor.withValues(alpha: opacity);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), layerSize, paint);
    }

    // 第5層: 主體核心
    paint.color = getHueVariation(color, 6).withValues(alpha: 0.55);
    canvas.drawCircle(center, strokeWidth * scale * 0.5, paint);

    // 第6層: 高光
    final highlightCount = 2 + nextInt(3);
    for (int i = 0; i < highlightCount; i++) {
      final offsetX = (nextRandom() - 0.75) * strokeWidth * scale * 0.5;
      final offsetY = (nextRandom() - 0.75) * strokeWidth * scale * 0.5;
      final highlightSize = strokeWidth * scale * (0.2 + nextRandom() * 0.2);
      final highlightColor = getHueVariation(color, 8);
      paint.color = highlightColor.withValues(alpha: 0.35 + nextRandom() * 0.25);
      canvas.drawCircle(Offset(center.dx + offsetX, center.dy + offsetY),
          highlightSize, paint);
    }

    // 第7層: 陰影
    final shadowCount = 1 + nextInt(3);
    for (int j = 0; j < shadowCount; j++) {
      final shadowX = (nextRandom() + 0.15) * strokeWidth * scale * 0.4;
      final shadowY = (nextRandom() + 0.15) * strokeWidth * scale * 0.4;
      final shadowSize = strokeWidth * scale * (0.15 + nextRandom() * 0.15);
      final shadowColor = getHueVariation(color, 8);
      paint.color = shadowColor.withValues(alpha: 0.15 + nextRandom() * 0.12);
      canvas.drawCircle(
          Offset(center.dx + shadowX, center.dy + shadowY), shadowSize, paint);
    }

    // 第8層: 邊緣毛邊
    final edgeCount = 3 + nextInt(4);
    for (int i = 0; i < edgeCount; i++) {
      final angleBase = (i / edgeCount) * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.6;
      final angle = angleBase + angleNoise;
      final distanceVariation = 0.6 + nextRandom() * 1.2;
      final distance = strokeWidth * scale * distanceVariation;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final edgeSize = strokeWidth * scale * (0.08 + math.pow(nextRandom(), 0.7) * 0.25);
      final edgeOpacity = 0.08 + nextRandom() * 0.22;
      final edgeColor = getHueVariation(color, 12);
      paint.color = edgeColor.withValues(alpha: edgeOpacity);
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), edgeSize, paint);
    }

    // 轉換為圖片
    final picture = recorder.endRecording();
    return await picture.toImage(_stampSize, _stampSize);
  }

  /// 確定性偽隨機數生成
  static double _deterministicRandom(int seed) {
    final hash = ((seed * 2654435761) ^ (seed >> 16)) & 0x7FFFFFFF;
    return (hash % 10000) / 10000.0;
  }

  /// 清理紋理
  void _disposeTextures() {
    for (var texture in _textures) {
      texture.dispose();
    }
  }

  /// 釋放資源
  void dispose() {
    _disposeTextures();
    _textures = [];
  }
}
