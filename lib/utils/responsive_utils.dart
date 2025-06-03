import 'package:flutter/material.dart';

/// Utilitários para design responsivo
class ResponsiveUtils {
  // Breakpoints para diferentes tamanhos de tela
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Verifica se a tela é mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Verifica se a tela é tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Verifica se a tela é desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Retorna o número de colunas baseado no tamanho da tela
  static int getColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Retorna o padding baseado no tamanho da tela
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  /// Retorna o espaçamento entre elementos baseado no tamanho da tela
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }

  /// Retorna o tamanho da fonte do título baseado no tamanho da tela
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) return 32;
    if (isTablet(context)) return 40;
    return 48;
  }

  /// Retorna o tamanho da fonte do subtítulo baseado no tamanho da tela
  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) return 14;
    if (isTablet(context)) return 16;
    return 18;
  }

  /// Retorna o tamanho da fonte do corpo baseado no tamanho da tela
  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) return 14;
    if (isTablet(context)) return 16;
    return 16;
  }

  /// Retorna a altura do botão baseado no tamanho da tela
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48;
    if (isTablet(context)) return 56;
    return 64;
  }

  /// Retorna o tamanho do ícone baseado no tamanho da tela
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 28;
    return 32;
  }

  /// Retorna a largura máxima do conteúdo
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }

  /// Widget responsivo que adapta baseado no tamanho da tela
  static Widget responsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Retorna o aspect ratio para cards baseado no tamanho da tela
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) return 16 / 9;
    if (isTablet(context)) return 4 / 3;
    return 3 / 2;
  }

  /// Retorna o número de itens por linha em um grid
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Retorna o espaçamento do grid baseado no tamanho da tela
  static double getGridSpacing(BuildContext context) {
    if (isMobile(context)) return 8;
    if (isTablet(context)) return 12;
    return 16;
  }
}

/// Widget que centraliza o conteúdo com largura máxima
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.getMaxContentWidth(context),
        ),
        padding: padding ?? ResponsiveUtils.getPadding(context),
        child: child,
      ),
    );
  }
}

/// Widget para texto responsivo
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
  });

  @override
  Widget build(BuildContext context) {
    double fontSize;

    if (ResponsiveUtils.isMobile(context)) {
      fontSize = mobileFontSize ?? 14;
    } else if (ResponsiveUtils.isTablet(context)) {
      fontSize = tabletFontSize ?? 16;
    } else {
      fontSize = desktopFontSize ?? 16;
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
