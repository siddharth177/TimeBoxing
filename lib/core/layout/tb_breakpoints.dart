import 'package:flutter/cupertino.dart';

abstract final class TbBreakpoints {
  static const double tablet = 720;
  static const double desktop = 1200;
  static const double sidebarWidth = 380.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
