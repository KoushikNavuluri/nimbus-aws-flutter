/*
 ┌────────────────────────────────────────────────────────────────────────┐
 │ NIMBUS · Fall for the cloud.                                Design plan  │
 └────────────────────────────────────────────────────────────────────────┘
 Spine     A trading-card album. Lessons are booster packs, services are cards,
           mastery is foil.
 Type      DynaPuff (display) · Figtree (UI) · JetBrains Mono (CLI) · Kalam (notes)
 Colour    Sky paper, cotton surfaces, midnight ink, ONE lead: flamingo.
           Seven Cloudling type colours. No AWS orange/navy.
 Signature Holographic Cloudling cards: tilt + rainbow foil that follows your finger.
*/
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  C._();
  static const sky = Color(0xFFE7EEFF);
  static const skyDeep = Color(0xFFD6E2FF);
  static const cotton = Color(0xFFFBFCFF);
  static const ink = Color(0xFF1D2352);
  static const ink2 = Color(0xFF4D5585);
  static const ink3 = Color(0xFF6E76A3);
  static const line = Color(0xFFD5DDF4);
  static const track = Color(0xFFE3E8F8);
  static const flamingo = Color(0xFFFF4D7E);
  static const flamingoDeep = Color(0xFFE0305F);
  static const flamingoSoft = Color(0xFFFFE3EB);
  static const mint = Color(0xFF14B886);
  static const mintDeep = Color(0xFF0B8A63);
  static const mintDark = Color(0xFF0E8F69);
  static const mintSoft = Color(0xFFDCF7EE);
  static const butter = Color(0xFFFFC23D);
  static const butterSoft = Color(0xFFFFF3D6);
  static const butterInk = Color(0xFF7A5200);
  static const danger = Color(0xFFE5484D);
  static const dangerDeep = Color(0xFFC7353A);
  static const dangerSoft = Color(0xFFFFE9EA);
  static const dangerInk = Color(0xFF9B1C21);
  static const night = Color(0xFF14173F);
  static const terminal = Color(0xFF161A40);
  static const note = Color(0xFFFFF3C4);
  static const grape = Color(0xFF8C7CFF);
  static const blue = Color(0xFF4AA3FF);
}

const kEase = Cubic(0.22, 1, 0.36, 1);
const kTabular = [FontFeature.tabularFigures()];

const kCardShadow = [
  BoxShadow(color: Color(0x0A1D2352), offset: Offset(0, 1)),
  BoxShadow(color: Color(0x4D1D2352), offset: Offset(0, 10), blurRadius: 28, spreadRadius: -16),
];
const kPopShadow = [BoxShadow(color: Color(0x731D2352), offset: Offset(0, 18), blurRadius: 40, spreadRadius: -16)];
const kSoftShadow = [BoxShadow(color: Color(0x471D2352), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -14)];

TextStyle _font(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

TextStyle tDisplay(double size, {Color color = C.ink, FontWeight weight = FontWeight.w600, double height = 1.06, double? spacing}) =>
    _font('DynaPuff', TextStyle(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing ?? -0.02 * size));

TextStyle tUi(double size,
        {Color color = C.ink, FontWeight weight = FontWeight.w500, double? height, double? spacing, TextDecoration? decoration, Color? decorationColor}) =>
    _font('Figtree', TextStyle(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing, decoration: decoration, decorationColor: decorationColor, decorationThickness: 2));

TextStyle tMono(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double? height}) =>
    _font('JetBrains Mono', TextStyle(fontSize: size, fontWeight: weight, color: color, height: height));

TextStyle tHand(double size, {Color color = C.ink, double height = 1.25}) =>
    _font('Kalam', TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, height: height));

TextStyle tEyebrow({Color color = C.ink3}) => tUi(12, weight: FontWeight.w700, color: color, spacing: 1.4);

/// Indian digit grouping: 1,00,00,000.
String fmtIN(num value) {
  final n = value.round();
  final neg = n < 0;
  var s = n.abs().toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last3';
  }
  return neg ? '-$s' : s;
}
