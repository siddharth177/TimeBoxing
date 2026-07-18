import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle _u({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => GoogleFonts.urbanist(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  // Display
  static TextStyle displayLg({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 48,
    weight: weight,
    height: 1.2,
    letterSpacing: -1.5,
    color: color,
  );

  static TextStyle displayMd({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 40,
    weight: weight,
    height: 1.2,
    letterSpacing: -1.2,
    color: color,
  );

  static TextStyle displaySm({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 32,
    weight: weight,
    height: 1.2,
    letterSpacing: -1.0,
    color: color,
  );

  // Headings
  static TextStyle heading2xl({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 30,
    weight: weight,
    height: 38 / 30,
    letterSpacing: -1.0,
    color: color,
  );

  static TextStyle headingXl({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 26,
    weight: weight,
    height: 1.3,
    letterSpacing: -0.8,
    color: color,
  );

  static TextStyle headingLg({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 22,
    weight: weight,
    height: 1.3,
    letterSpacing: -0.6,
    color: color,
  );

  static TextStyle headingMd({
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) => _u(
    size: 20,
    weight: weight,
    height: 1.3,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle headingSm({
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) => _u(
    size: 18,
    weight: weight,
    height: 1.3,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle headingXs({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) => _u(
    size: 16,
    weight: weight,
    height: 1.3,
    letterSpacing: -0.2,
    color: color,
  );

  // Body text
  static TextStyle textXl({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) => _u(
    size: 18,
    weight: weight,
    height: 1.0,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle textLg({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => _u(
    size: 16,
    weight: weight,
    height: 1.6,
    letterSpacing: -0.3,
    color: color,
  );

  static TextStyle textMd({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => _u(
    size: 14,
    weight: weight,
    height: 1.5,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle textSm({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => _u(
    size: 12,
    weight: weight,
    height: 1.4,
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle textXs({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => _u(size: 10, weight: weight, height: 1.3, color: color);

  // Labels (buttons etc.)
  static TextStyle labelLg({Color? color}) => _u(
    size: 18,
    weight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle labelMd({Color? color}) => _u(
    size: 14,
    weight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle labelSm({Color? color}) => _u(
    size: 12,
    weight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.1,
    color: color,
  );
}
