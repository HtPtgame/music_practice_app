import 'package:flutter/material.dart';

/// 自動調整字體大小的文字組件，避免顯示刪節號
class AutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final double minFontSize;
  final double maxFontSize;
  final TextOverflow overflow;

  const AutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.minFontSize = 10,
    this.maxFontSize = double.infinity,
    this.overflow = TextOverflow.visible,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final baseFontSize = baseStyle.fontSize ?? 14.0;
    final effectiveMaxFontSize = maxFontSize == double.infinity ? baseFontSize : maxFontSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算文字所需寬度
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: baseStyle),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        // 如果文字能完全顯示，使用原始大小
        if (!textPainter.didExceedMaxLines) {
          return Text(
            text,
            style: style,
            maxLines: maxLines,
            textAlign: textAlign,
            overflow: overflow,
          );
        }

        // 二分搜索找到合適的字體大小
        double fontSize = effectiveMaxFontSize;
        double minSize = minFontSize;
        double maxSize = effectiveMaxFontSize;

        while (maxSize - minSize > 0.5) {
          fontSize = (minSize + maxSize) / 2;
          final testPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: baseStyle.copyWith(fontSize: fontSize),
            ),
            maxLines: maxLines,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          if (testPainter.didExceedMaxLines) {
            maxSize = fontSize;
          } else {
            minSize = fontSize;
          }
        }

        return Text(
          text,
          style: baseStyle.copyWith(fontSize: fontSize),
          maxLines: maxLines,
          textAlign: textAlign,
          overflow: overflow,
        );
      },
    );
  }
}
