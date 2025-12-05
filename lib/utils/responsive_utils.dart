// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

/// 響應式工具類
/// 提供統一的螢幕尺寸適配方法，避免畫面破圖
class ResponsiveUtils {
  /// 獲取螢幕寬度
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 獲取螢幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 獲取可用高度（扣除鍵盤高度）
  static double availableHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return screenHeight - keyboardHeight;
  }

  /// 獲取鍵盤高度
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// 判斷鍵盤是否顯示
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// 獲取安全區域內邊距
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 獲取底部安全區域高度
  static double safeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 判斷是否為小螢幕設備 (寬度 < 360)
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// 判斷是否為中型螢幕設備 (360 <= 寬度 < 600)
  static bool isMediumScreen(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// 判斷是否為大螢幕設備 (寬度 >= 600)
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// 判斷是否為平板設備 (寬度 >= 768)
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 768;
  }

  /// 根據螢幕寬度返回響應式值
  /// small: 小螢幕值, medium: 中螢幕值, large: 大螢幕值
  static T responsive<T>(
    BuildContext context, {
    required T small,
    T? medium,
    T? large,
  }) {
    if (isLargeScreen(context)) {
      return large ?? medium ?? small;
    } else if (isMediumScreen(context)) {
      return medium ?? small;
    }
    return small;
  }

  /// 響應式字體大小
  /// 基礎尺寸會根據螢幕寬度自動調整
  static double fontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < 360) {
      return baseSize * 0.9; // 小螢幕縮小 10%
    } else if (width >= 768) {
      return baseSize * 1.1; // 平板放大 10%
    }
    return baseSize; // 標準尺寸
  }

  /// 響應式內邊距
  /// 基礎內邊距會根據螢幕寬度自動調整
  static double padding(BuildContext context, double basePadding) {
    final width = screenWidth(context);
    if (width < 360) {
      return basePadding * 0.8; // 小螢幕縮小 20%
    } else if (width >= 768) {
      return basePadding * 1.2; // 平板放大 20%
    }
    return basePadding; // 標準尺寸
  }

  /// 響應式間距 (SizedBox)
  static double spacing(BuildContext context, double baseSpacing) {
    return padding(context, baseSpacing);
  }

  /// 響應式圖標大小
  static double iconSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < 360) {
      return baseSize * 0.85;
    } else if (width >= 768) {
      return baseSize * 1.15;
    }
    return baseSize;
  }

  /// 響應式按鈕高度
  static double buttonHeight(BuildContext context) {
    return responsive(
      context,
      small: 48.0,
      medium: 52.0,
      large: 56.0,
    );
  }

  /// 響應式卡片內邊距
  static EdgeInsets cardPadding(BuildContext context) {
    final basePadding = padding(context, 16.0);
    return EdgeInsets.all(basePadding);
  }

  /// 響應式頁面內邊距
  static EdgeInsets pagePadding(BuildContext context) {
    final basePadding = padding(context, 16.0);
    return EdgeInsets.all(basePadding);
  }

  /// 響應式水平內邊距
  static EdgeInsets horizontalPadding(BuildContext context, double basePadding) {
    final responsivePadding = padding(context, basePadding);
    return EdgeInsets.symmetric(horizontal: responsivePadding);
  }

  /// 響應式垂直內邊距
  static EdgeInsets verticalPadding(BuildContext context, double basePadding) {
    final responsivePadding = padding(context, basePadding);
    return EdgeInsets.symmetric(vertical: responsivePadding);
  }

  /// 響應式對稱內邊距
  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: padding(context, horizontal),
      vertical: padding(context, vertical),
    );
  }

  /// 響應式圓角半徑
  static double borderRadius(BuildContext context, double baseRadius) {
    final width = screenWidth(context);
    if (width < 360) {
      return baseRadius * 0.9;
    } else if (width >= 768) {
      return baseRadius * 1.1;
    }
    return baseRadius;
  }

  /// 響應式間距組件
  static Widget verticalSpace(BuildContext context, double baseHeight) {
    return SizedBox(height: spacing(context, baseHeight));
  }

  /// 響應式水平間距組件
  static Widget horizontalSpace(BuildContext context, double baseWidth) {
    return SizedBox(width: spacing(context, baseWidth));
  }

  /// 響應式最大寬度約束
  /// 用於大螢幕時限制內容寬度，提升可讀性
  static BoxConstraints maxWidthConstraint(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) {
      return const BoxConstraints(maxWidth: 1000);
    } else if (width >= 900) {
      return const BoxConstraints(maxWidth: 800);
    } else if (width >= 768) {
      return const BoxConstraints(maxWidth: 600);
    }
    return const BoxConstraints();
  }

  /// 響應式列數 (用於 GridView)
  static int gridCrossAxisCount(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) {
      return 4; // 超大螢幕 4 列
    } else if (width >= 900) {
      return 3; // 大螢幕 3 列
    } else if (width >= 600) {
      return 2; // 平板 2 列
    }
    return 1; // 手機 1 列
  }

  /// 響應式文字樣式
  static TextStyle textStyle(
    BuildContext context, {
    double fontSize = 14,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// 響應式標題樣式
  static TextStyle headingStyle(
    BuildContext context, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// 響應式副標題樣式
  static TextStyle subtitleStyle(
    BuildContext context, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// 響應式正文樣式
  static TextStyle bodyStyle(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// 響應式小字樣式
  static TextStyle captionStyle(
    BuildContext context, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
    );
  }
}

/// 響應式 Widget Builder
/// 根據螢幕尺寸返回不同的 Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) small;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? large;

  const ResponsiveBuilder({
    super.key,
    required this.small,
    this.medium,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLargeScreen(context)) {
      return (large ?? medium ?? small)(context);
    } else if (ResponsiveUtils.isMediumScreen(context)) {
      return (medium ?? small)(context);
    }
    return small(context);
  }
}

/// 響應式 BottomSheet 幫助類
/// 自動處理鍵盤彈出和安全區域
class ResponsiveBottomSheet {
  /// 顯示響應式 BottomSheet
  /// 自動處理鍵盤彈出時的佈局問題
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, double bottomInset) builder,
    double maxHeightRatio = 0.9,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * maxHeightRatio;
        
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            borderRadius: borderRadius ?? const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: builder(context, bottomInset),
          ),
        );
      },
    );
  }
}

/// 鍵盤安全 Scaffold 包裝器
/// 自動處理鍵盤彈出時的佈局問題
class KeyboardSafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const KeyboardSafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar != null
          ? SafeArea(child: bottomNavigationBar!)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
