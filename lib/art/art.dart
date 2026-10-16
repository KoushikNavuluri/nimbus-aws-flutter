// Hand-built SVG Cloudlings. One family: ink outline, blush, glinting eyes, one prop each.
// Every critter is generated as an SVG string and rendered by flutter_svg (cached).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/services.dart';

const _ink = '#1D2352';

String _n(num v) {
  final s = v.toStringAsFixed(2);
  final t = s.replaceFirst(RegExp(r'0+$'), '');
  return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
}

String _st([num w = 3]) => 'stroke="$_ink" stroke-width="${_n(w)}" stroke-linejoin="round" stroke-linecap="round"';

String _rgb(int r, int g, int b) => '#${((r << 16) | (g << 8) | b).toRadixString(16).padLeft(6, '0')}';

String hexOf(int argb) => _rgb((argb >> 16) & 255, (argb >> 8) & 255, argb & 255);

String tintHex(int argb, double amt) {
  int f(int v) => (v + (255 - v) * amt).round().clamp(0, 255);
  return _rgb(f((argb >> 16) & 255), f((argb >> 8) & 255), f(argb & 255));
}

String shadeHex(int argb, double amt) {
  int f(int v) => (v * (1 - amt)).round().clamp(0, 255);
  return _rgb(f((argb >> 16) & 255), f((argb >> 8) & 255), f(argb & 255));
}

Color tintColor(Color c, double amt) => Color.lerp(c, const Color(0xFFFFFFFF), amt)!;
Color shadeColor(Color c, double amt) => Color.lerp(c, const Color(0xFF000000), amt)!;

// ───────── face ─────────
String _face(num x, num y, {num s = 1, String mood = 'happy', bool blink = false}) {
  final ex = 11 * s;
  final String eyes;
  if (mood == 'sleepy' || (blink && mood != 'cheer')) {
    eyes = '<g fill="none" stroke="$_ink" stroke-width="${_n(2.6 * s)}" stroke-linecap="round">'
        '<path d="M${_n(x - ex - 4 * s)} ${_n(y)} q${_n(4 * s)} ${_n(3.5 * s)} ${_n(8 * s)} 0"/>'
        '<path d="M${_n(x + ex - 4 * s)} ${_n(y)} q${_n(4 * s)} ${_n(3.5 * s)} ${_n(8 * s)} 0"/></g>';
  } else if (mood == 'cheer') {
    eyes = '<g fill="none" stroke="$_ink" stroke-width="${_n(2.8 * s)}" stroke-linecap="round">'
        '<path d="M${_n(x - ex - 4 * s)} ${_n(y + s)} q${_n(4 * s)} ${_n(-5 * s)} ${_n(8 * s)} 0"/>'
        '<path d="M${_n(x + ex - 4 * s)} ${_n(y + s)} q${_n(4 * s)} ${_n(-5 * s)} ${_n(8 * s)} 0"/></g>';
  } else {
    final k = mood == 'think' ? 1 : 0;
    eyes = '<ellipse cx="${_n(x - ex)}" cy="${_n(y)}" rx="${_n(3.9 * s)}" ry="${_n(4.9 * s)}" fill="$_ink"/>'
        '<ellipse cx="${_n(x + ex)}" cy="${_n(y)}" rx="${_n(3.9 * s)}" ry="${_n(4.9 * s)}" fill="$_ink"/>'
        '<circle cx="${_n(x - ex + 1.3 * s + k)}" cy="${_n(y - 1.9 * s - k)}" r="${_n(1.5 * s)}" fill="#fff"/>'
        '<circle cx="${_n(x + ex + 1.3 * s + k)}" cy="${_n(y - 1.9 * s - k)}" r="${_n(1.5 * s)}" fill="#fff"/>';
  }
  final my = y + 6.5 * s;
  String line(num x0, num y0, num qx, num qy, num w, num sw) =>
      '<path d="M${_n(x0)} ${_n(y0)} q${_n(qx)} ${_n(qy)} ${_n(w)} 0" fill="none" stroke="$_ink" stroke-width="${_n(sw)}" stroke-linecap="round"/>';
  String mouth = '';
  if (mood == 'happy') {
    mouth = line(x - 4.5 * s, my, 4.5 * s, 4.6 * s, 9 * s, 2.5 * s);
  } else if (mood == 'soft') {
    mouth = line(x - 3 * s, my + 0.5 * s, 3 * s, 2.6 * s, 6 * s, 2.3 * s);
  } else if (mood == 'cheer') {
    mouth = '<path d="M${_n(x - 5.5 * s)} ${_n(my - 0.5 * s)} q${_n(5.5 * s)} ${_n(8 * s)} ${_n(11 * s)} 0 z" fill="$_ink"/>'
        '<path d="M${_n(x - 2.6 * s)} ${_n(my + 2.6 * s)} q${_n(2.6 * s)} ${_n(2 * s)} ${_n(5.2 * s)} 0" fill="#FF7FA6"/>';
  } else if (mood == 'wow') {
    mouth = '<ellipse cx="${_n(x)}" cy="${_n(my + 2 * s)}" rx="${_n(2.8 * s)}" ry="${_n(3.4 * s)}" fill="$_ink"/>';
  } else if (mood == 'think') {
    mouth = line(x - 3.5 * s, my + 1.5 * s, 3.5 * s, -1.5 * s, 7 * s, 2.4 * s);
  } else if (mood == 'sleepy') {
    mouth = '<ellipse cx="${_n(x)}" cy="${_n(my + 1.5 * s)}" rx="${_n(2.2 * s)}" ry="${_n(1.8 * s)}" fill="$_ink"/>';
  } else if (mood == 'sad') {
    mouth = line(x - 4 * s, my + 3 * s, 4 * s, -3.6 * s, 8 * s, 2.4 * s);
  }
  final blush = '<ellipse cx="${_n(x - ex - 6.5 * s)}" cy="${_n(y + 7 * s)}" rx="${_n(4.6 * s)}" ry="${_n(2.7 * s)}" fill="#FF7FA6" fill-opacity=".55"/>'
      '<ellipse cx="${_n(x + ex + 6.5 * s)}" cy="${_n(y + 7 * s)}" rx="${_n(4.6 * s)}" ry="${_n(2.7 * s)}" fill="#FF7FA6" fill-opacity=".55"/>';
  return '<g>$eyes$blush$mouth</g>';
}

String _shine(num x, num y, [num r = 6, num rot = -30]) =>
    '<ellipse cx="${_n(x)}" cy="${_n(y)}" rx="${_n(r)}" ry="${_n(r * 0.55)}" fill="#fff" fill-opacity=".55" transform="rotate(${_n(rot)} ${_n(x)} ${_n(y)})"/>';

String _duck(num x, num y, num s, String c, String dark, {bool lead = false, String mood = 'happy', bool blink = false}) {
  final head = lead
      ? _face(x + 5 * s, y - 17 * s, s: 0.55, mood: mood, blink: blink)
      : '<circle cx="${_n(x + 2.5 * s)}" cy="${_n(y - 18 * s)}" r="${_n(2.3 * s)}" fill="$_ink"/><circle cx="${_n(x + 10 * s)}" cy="${_n(y - 18 * s)}" r="${_n(2.3 * s)}" fill="$_ink"/>';
  return '<g>'
      '<ellipse cx="${_n(x)}" cy="${_n(y)}" rx="${_n(17 * s)}" ry="${_n(13 * s)}" fill="$c" ${_st()}/>'
      '<path d="M${_n(x - 6 * s)} ${_n(y)} q${_n(6 * s)} ${_n(6 * s)} ${_n(12 * s)} 0" stroke="$dark" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
      '<circle cx="${_n(x + 6 * s)}" cy="${_n(y - 16 * s)}" r="${_n(11 * s)}" fill="$c" ${_st()}/>'
      '<path d="M${_n(x + 16 * s)} ${_n(y - 18 * s)} q${_n(9 * s)} ${_n(2.5 * s)} 0 ${_n(6.5 * s)} z" fill="#FFB547" ${_st(2.4)}/>'
      '$head</g>';
}

class _A {
  const _A(this.c, this.light, this.dark, this.mood, this.blink);
  final String c;
  final String light;
  final String dark;
  final String mood;
  final bool blink;
  String face(num x, num y, [num s = 1]) => _face(x, y, s: s, mood: mood, blink: blink);
}

final Map<String, String Function(_A a)> _art = {
  'ec2': (a) => '<line x1="60" y1="34" x2="60" y2="20" ${_st()}/>'
      '<circle cx="60" cy="16" r="5.5" fill="#FF4D7E" ${_st()}/>'
      '<rect x="36" y="94" width="14" height="10" rx="4" fill="${a.dark}" ${_st(2.5)}/>'
      '<rect x="70" y="94" width="14" height="10" rx="4" fill="${a.dark}" ${_st(2.5)}/>'
      '<circle cx="22" cy="64" r="4.5" fill="${a.dark}" ${_st(2.5)}/>'
      '<circle cx="98" cy="64" r="4.5" fill="${a.dark}" ${_st(2.5)}/>'
      '<rect x="24" y="34" width="72" height="64" rx="18" fill="${a.c}" ${_st()}/>'
      '<rect x="32" y="42" width="56" height="34" rx="12" fill="${a.light}"/>'
      '${_shine(34, 40, 5)}${a.face(60, 57)}'
      '<g stroke="${a.dark}" stroke-width="3" stroke-linecap="round"><line x1="44" y1="87" x2="51" y2="87"/><line x1="56.5" y1="87" x2="63.5" y2="87"/><line x1="69" y1="87" x2="76" y2="87"/></g>',
  'lambda': (a) => '<path d="M58 12 L46 34 L57 32 L51 48 L71 25 L60 27 L67 12 Z" fill="#FFC23D" ${_st()}/>'
      '<path d="M30 74 q-10 -2 -11 -12" fill="none" ${_st()}/>'
      '<path d="M90 74 q10 -2 11 -12" fill="none" ${_st()}/>'
      '<circle cx="60" cy="69" r="32" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="60" cy="84" rx="18" ry="12" fill="${a.light}"/>'
      '${_shine(40, 50)}'
      '<path d="M54.5 76 H58.5 L67 94 M60.5 84 L53 94" stroke="${a.dark}" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
      '${a.face(60, 60)}',
  's3': (a) => '<path d="M28 46 Q60 -4 92 46" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
      '<path d="M26 44 L34 96 Q60 106 86 96 L94 44 Z" fill="${a.c}" ${_st()}/>'
      '<path d="M31.5 80 Q60 90 88.5 80" stroke="${a.dark}" stroke-width="3" fill="none" stroke-opacity=".45"/>'
      '<ellipse cx="60" cy="44" rx="34" ry="9" fill="${a.light}" ${_st()}/>'
      '<ellipse cx="60" cy="44" rx="25" ry="4.6" fill="${a.dark}" fill-opacity=".35"/>'
      '<circle cx="27" cy="47" r="3.6" fill="$_ink"/><circle cx="93" cy="47" r="3.6" fill="$_ink"/>'
      '${_shine(36, 58, 5, -70)}${a.face(60, 66)}',
  'ebs': (a) => '<path d="M97 72 q16 4 11 18 q-4 9 -14 8" fill="none" ${_st()}/>'
      '<rect x="86" y="93" width="11" height="9" rx="2.5" fill="#FFC23D" ${_st(2.5)}/>'
      '<path d="M22 48 V78 A38 13 0 0 0 98 78 V48 Z" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="60" cy="48" rx="38" ry="13" fill="${a.light}" ${_st()}/>'
      '<ellipse cx="60" cy="48" rx="10" ry="3.8" fill="${a.c}" ${_st(2.5)}/>'
      '${_shine(30, 64, 4, -80)}${a.face(60, 68, 0.95)}',
  'rds': (a) => '<path d="M32 30 V90 A28 9 0 0 0 88 90 V30 Z" fill="${a.c}" ${_st()}/>'
      '<path d="M32 44 A28 9 0 0 0 88 44" fill="none" stroke="${a.dark}" stroke-width="2.6" stroke-opacity=".55"/>'
      '<path d="M32 82 A28 9 0 0 0 88 82" fill="none" stroke="${a.dark}" stroke-width="2.6" stroke-opacity=".55"/>'
      '<ellipse cx="60" cy="30" rx="28" ry="9" fill="${a.light}" ${_st()}/>'
      '${a.face(60, 63)}'
      '<g fill="#fff" fill-opacity=".28" stroke="$_ink" stroke-width="2.4"><circle cx="49" cy="63" r="7.6"/><circle cx="71" cy="63" r="7.6"/></g>'
      '<path d="M56.6 62 q3.4 -3 6.8 0" stroke="$_ink" stroke-width="2.4" fill="none"/>',
  'dynamodb': (a) => '<g stroke="${a.dark}" stroke-width="3" stroke-linecap="round" stroke-opacity=".75"><line x1="8" y1="56" x2="20" y2="56"/><line x1="4" y1="68" x2="19" y2="68"/><line x1="8" y1="80" x2="20" y2="80"/></g>'
      '<path d="M60 30 C88 30 94 44 94 66 C94 90 82 100 60 100 C38 100 26 90 26 66 C26 44 32 30 60 30 Z" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="60" cy="86" rx="20" ry="9" fill="${a.light}"/>'
      '<path d="M63 33 L54 47 L61 47 L57 58 L69 42 L62 42 L66 33 Z" fill="#FFC23D" ${_st(2.4)}/>'
      '${_shine(38, 48)}${a.face(60, 69)}'
      '<ellipse cx="45" cy="101" rx="10" ry="5" fill="#fff" ${_st(2.5)}/>'
      '<ellipse cx="75" cy="101" rx="10" ry="5" fill="#fff" ${_st(2.5)}/>',
  'elasticache': (a) => '<path d="M72 50 L110 30 L101 50 L115 53 L99 64 L107 81 L75 78 Z" fill="${a.light}" ${_st()}/>'
      '<circle cx="56" cy="67" r="30" fill="${a.c}" ${_st()}/>'
      '<path d="M44 28 l3 8 8 3 -8 3 -3 8 -3 -8 -8 -3 8 -3z" fill="#FFC23D" ${_st(2.2)}/>'
      '<circle cx="24" cy="36" r="2.5" fill="#FFC23D"/><circle cx="92" cy="100" r="2.5" fill="#FFC23D"/>'
      '${_shine(38, 52)}${a.face(56, 66)}',
  'vpc': (a) => '<rect x="9" y="14" width="102" height="96" rx="32" fill="${a.light}" stroke="${a.dark}" stroke-width="3" stroke-dasharray="7 6"/>'
      '<path d="M60 37 q-2 -11 -11 -13 q2 9 11 13 q2 -11 11 -13 q-2 9 -11 13" fill="#86CF4E" ${_st(2.2)}/>'
      '<path d="M60 37 C84 37 92 52 92 70 C92 90 80 99 60 99 C40 99 28 90 28 70 C28 52 36 37 60 37Z" fill="${a.c}" ${_st()}/>'
      '${_shine(40, 54)}${a.face(60, 69)}',
  'cloudfront': (a) => '<path d="M31 64 L3 50 L10 80 Z" fill="#fff" ${_st()}/>'
      '<path d="M89 64 L117 50 L110 80 Z" fill="#fff" ${_st()}/>'
      '<path d="M31 64 L10 80" fill="none" stroke="${a.dark}" stroke-width="2" stroke-opacity=".5"/><path d="M89 64 L110 80" fill="none" stroke="${a.dark}" stroke-width="2" stroke-opacity=".5"/>'
      '<ellipse cx="60" cy="68" rx="32" ry="29" fill="${a.c}" ${_st()}/>'
      '<rect x="31" y="43" width="58" height="8" rx="4" fill="${a.dark}"/>'
      '<circle cx="47" cy="47" r="7" fill="${a.light}" ${_st(2.4)}/><circle cx="73" cy="47" r="7" fill="${a.light}" ${_st(2.4)}/>'
      '${a.face(60, 70)}'
      '<path d="M42 106 h36" fill="none" stroke="${a.dark}" stroke-width="3" stroke-linecap="round" stroke-opacity=".45"/>',
  'route53': (a) => '<path d="M40 107 q20 -7 40 0" stroke="#86CF4E" stroke-width="4" stroke-linecap="round" fill="none"/>'
      '<rect x="53" y="62" width="14" height="44" rx="4" fill="#F2C49B" ${_st()}/>'
      '<text x="60" y="92" text-anchor="middle" font-family="sans-serif" font-size="10.5" font-weight="700" fill="$_ink">53</text>'
      '<path d="M22 24 H86 L104 46 L86 68 H22 Q15 68 15 61 V31 Q15 24 22 24 Z" fill="${a.c}" ${_st()}/>'
      '<rect x="21" y="29" width="62" height="34" rx="9" fill="${a.light}" fill-opacity=".55"/>'
      '${a.face(54, 45, 0.95)}',
  'elb': (a) => '<path d="M32 36 Q60 -2 88 36" stroke="$_ink" stroke-width="2" stroke-dasharray="2 6" fill="none" stroke-opacity=".45"/>'
      '<circle cx="31" cy="27" r="8" fill="#FF4D7E" ${_st(2.5)}/>'
      '<circle cx="60" cy="13" r="8" fill="#FFC23D" ${_st(2.5)}/>'
      '<circle cx="89" cy="27" r="8" fill="#2FCCAA" ${_st(2.5)}/>'
      '<path d="M33 70 q-11 -12 -3 -27" fill="none" ${_st()}/>'
      '<path d="M87 70 q11 -12 3 -27" fill="none" ${_st()}/>'
      '<ellipse cx="60" cy="74" rx="31" ry="29" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="60" cy="90" rx="17" ry="9" fill="${a.light}"/>'
      '${_shine(42, 58)}${a.face(60, 71)}',
  'apigateway': (a) => '<path d="M28 101 V56 Q28 24 60 24 Q92 24 92 56 V101 Z" fill="${a.c}" ${_st()}/>'
      '<path d="M55 24 L57 33 H63 L65 24 Z" fill="${a.light}" ${_st(2)}/>'
      '<path d="M47 101 V87 Q47 76 60 76 Q73 76 73 87 V101 Z" fill="${a.dark}" ${_st(2.5)}/>'
      '<circle cx="68" cy="90" r="2" fill="#FFC23D"/>'
      '<line x1="18" y1="101" x2="102" y2="101" ${_st()}/>'
      '${_shine(38, 44)}${a.face(60, 54)}',
  'iam': (a) => '<g transform="rotate(-22 100 70)">'
      '<circle cx="100" cy="52" r="8.5" fill="#FFC23D" ${_st(2.6)}/>'
      '<circle cx="100" cy="52" r="3" fill="#fff" stroke="$_ink" stroke-width="1.8"/>'
      '<rect x="97.4" y="60" width="5.2" height="27" rx="2" fill="#FFC23D" ${_st(2.4)}/>'
      '<rect x="102" y="78" width="7" height="4.5" rx="1" fill="#FFC23D" ${_st(2)}/>'
      '</g>'
      '<rect x="26" y="40" width="68" height="62" rx="27" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="60" cy="90" rx="18" ry="8" fill="${a.light}"/>'
      '<path d="M31 44 Q60 18 89 44 Z" fill="${a.dark}" ${_st()}/>'
      '<rect x="24" y="41" width="72" height="8" rx="4" fill="$_ink"/>'
      '<circle cx="60" cy="33" r="4" fill="#FFC23D" stroke="$_ink" stroke-width="2"/>'
      '<path d="M91 80 q9 -2 9 -11" fill="none" ${_st()}/>'
      '${a.face(60, 68)}',
  'kms': (a) => '<path d="M40 58 V40 Q40 20 60 20 Q80 20 80 40 V58" fill="none" stroke="$_ink" stroke-width="10" stroke-linecap="round"/>'
      '<path d="M40 58 V40 Q40 20 60 20 Q80 20 80 40 V58" fill="none" stroke="#D5DBF2" stroke-width="4" stroke-linecap="round"/>'
      '<rect x="24" y="50" width="72" height="54" rx="17" fill="${a.c}" ${_st()}/>'
      '${_shine(34, 60, 5)}${a.face(60, 71)}'
      '<circle cx="60" cy="89" r="3.6" fill="$_ink"/><path d="M58.3 90 h3.4 l1 7 h-5.4z" fill="$_ink"/>',
  'sqs': (a) => _duck(20, 94, 0.68, a.c, a.dark) + _duck(47, 90, 0.9, a.c, a.dark) + _duck(80, 82, 1.25, a.c, a.dark, lead: true, mood: a.mood, blink: a.blink),
  'sns': (a) => '<path d="M108 52 q8 14 0 28" fill="none" ${_st(2.6)}/>'
      '<path d="M114 45 q12 21 0 42" fill="none" ${_st(2.6)} stroke-opacity=".45"/>'
      '<path d="M80 58 L104 44 V88 L80 74 Z" fill="#FFC23D" ${_st()}/>'
      '<rect x="72" y="58" width="11" height="16" rx="3" fill="${a.dark}" ${_st(2.5)}/>'
      '<circle cx="48" cy="68" r="30" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="46" cy="84" rx="16" ry="9" fill="${a.light}"/>'
      '<path d="M74 72 q-5 8 -12 6" fill="none" ${_st()}/>'
      '${_shine(30, 52)}${a.face(46, 63)}',
  'cloudwatch': (a) {
    final closed = a.mood == 'sleepy' || a.blink;
    final eyes = closed
        ? '<g stroke="$_ink" stroke-width="2.6" fill="none" stroke-linecap="round"><path d="M40 60 q6 4 12 0"/><path d="M68 60 q6 4 12 0"/></g>'
        : '<circle cx="47" cy="59" r="5.6" fill="$_ink"/><circle cx="75" cy="59" r="5.6" fill="$_ink"/><circle cx="49" cy="57" r="1.8" fill="#fff"/><circle cx="77" cy="57" r="1.8" fill="#fff"/>';
    return '<path d="M35 42 L29 17 L52 32 Z" fill="${a.dark}" ${_st()}/>'
        '<path d="M85 42 L91 17 L68 32 Z" fill="${a.dark}" ${_st()}/>'
        '<path d="M60 28 C88 28 96 48 96 70 C96 94 80 104 60 104 C40 104 24 94 24 70 C24 48 32 28 60 28 Z" fill="${a.c}" ${_st()}/>'
        '<ellipse cx="60" cy="87" rx="22" ry="14" fill="${a.light}"/>'
        '<g stroke="${a.dark}" stroke-width="2" fill="none" stroke-linecap="round" stroke-opacity=".6"><path d="M50 84 q3 3 6 0"/><path d="M58 90 q3 3 6 0"/><path d="M64 82 q3 3 6 0"/></g>'
        '<circle cx="46" cy="58" r="12.5" fill="#fff" ${_st()}/><circle cx="74" cy="58" r="12.5" fill="#fff" ${_st()}/>'
        '$eyes'
        '<path d="M55.5 68 L64.5 68 L60 76 Z" fill="#FFB547" ${_st(2.4)}/>'
        '<ellipse cx="34" cy="74" rx="4.6" ry="2.7" fill="#FF7FA6" fill-opacity=".55"/><ellipse cx="86" cy="74" rx="4.6" ry="2.7" fill="#FF7FA6" fill-opacity=".55"/>';
  },
  'cloudtrail': (a) => '<g fill="${a.dark}" fill-opacity=".5"><ellipse cx="12" cy="106" rx="4" ry="2.6"/><ellipse cx="21" cy="99" rx="4" ry="2.6"/><ellipse cx="12" cy="91" rx="4" ry="2.6"/></g>'
      '<ellipse cx="57" cy="72" rx="31" ry="29" fill="${a.c}" ${_st()}/>'
      '<ellipse cx="57" cy="88" rx="17" ry="9" fill="${a.light}"/>'
      '<path d="M30 52 Q57 22 84 52 Z" fill="${a.dark}" ${_st()}/>'
      '<path d="M23 52 H91" fill="none" stroke="$_ink" stroke-width="4.5" stroke-linecap="round"/>'
      '${a.face(57, 70)}'
      '<path d="M100 87 L110 99" fill="none" stroke="$_ink" stroke-width="5.5" stroke-linecap="round"/>'
      '<circle cx="94" cy="80" r="11" fill="#fff" fill-opacity=".7" stroke="$_ink" stroke-width="3.2"/>'
      '<path d="M89 76 q3 -3 6 -2" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>',
};

final Map<String, String> _cache = {};

/// SVG markup for one Cloudling (viewBox 0 0 120 120).
String critterSvg(String id, {String mood = 'happy', bool shadow = true, bool blink = false}) {
  final key = 'c|$id|$mood|$shadow|$blink';
  final hit = _cache[key];
  if (hit != null) return hit;
  final s = kSvc[id];
  final art = _art[id];
  if (s == null || art == null) return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120"></svg>';
  final c = hexOf(s.t.argb);
  final body = art(_A(c, tintHex(s.t.argb, 0.55), shadeHex(s.t.argb, 0.28), mood, blink));
  final sh = shadow ? '<ellipse cx="60" cy="111" rx="30" ry="4.5" fill="$_ink" fill-opacity=".1"/>' : '';
  final out = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">$sh<g>$body</g></svg>';
  _cache[key] = out;
  return out;
}

const _blobs = [
  [70, 62, 31],
  [42, 74, 21],
  [98, 74, 21],
  [54, 49, 20],
  [87, 51, 18],
  [70, 84, 24],
];

/// SVG markup for Puff the mascot (viewBox 0 0 140 120).
String puffSvg({String mood = 'happy', bool cap = false, bool glow = false, bool blink = false}) {
  final key = 'p|$mood|$cap|$glow|$blink';
  final hit = _cache[key];
  if (hit != null) return hit;
  final b = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 120" width="140" height="120">');
  if (glow) b.write('<ellipse cx="70" cy="70" rx="62" ry="48" fill="#fff" fill-opacity=".35"/>');
  b.write('<ellipse cx="70" cy="112" rx="38" ry="4.5" fill="$_ink" fill-opacity=".1"/>');
  b.write('<g fill="$_ink">');
  for (final o in _blobs) {
    b.write('<circle cx="${o[0]}" cy="${o[1]}" r="${o[2] + 3}"/>');
  }
  b.write('<rect x="31" y="70" width="78" height="31" rx="15"/></g>');
  b.write('<g fill="#fff">');
  for (final o in _blobs) {
    b.write('<circle cx="${o[0]}" cy="${o[1]}" r="${o[2]}"/>');
  }
  b.write('<rect x="34" y="73" width="72" height="25" rx="12.5"/></g>');
  b.write('<ellipse cx="70" cy="92" rx="30" ry="5" fill="#E2E9FF"/>');
  b.write('<ellipse cx="52" cy="40" rx="7" ry="3.6" fill="#EEF2FF" transform="rotate(-25 52 40)"/>');
  b.write(_face(70, 70, s: 1.45, mood: mood, blink: blink));
  if (cap) {
    b.write('<g><path d="M48 38 Q60 8 98 15 Q86 25 90 40 Q70 30 48 38 Z" fill="#8C7CFF" stroke="$_ink" stroke-width="3" stroke-linejoin="round"/>'
        '<path d="M46 38 Q70 28 92 40" stroke="$_ink" stroke-width="3" fill="none" stroke-linecap="round"/>'
        '<circle cx="100" cy="15" r="6.5" fill="#fff" stroke="$_ink" stroke-width="3"/>'
        '<circle cx="62" cy="24" r="1.8" fill="#FFC23D"/><circle cx="76" cy="20" r="1.6" fill="#FFC23D"/></g>');
  }
  if (mood == 'think') {
    b.write('<g fill="#fff" stroke="$_ink" stroke-width="2.5"><circle cx="116" cy="34" r="4"/><circle cx="126" cy="22" r="5.5"/></g>');
  }
  if (mood == 'cheer') {
    b.write('<g fill="#FFC23D" stroke="$_ink" stroke-width="2" stroke-linejoin="round">'
        '<path d="M14 34 l2.5 6 6 2.5 -6 2.5 -2.5 6 -2.5 -6 -6 -2.5 6 -2.5z"/>'
        '<path d="M124 30 l2 5 5 2 -5 2 -2 5 -2 -5 -5 -2 5 -2z"/></g>');
  }
  if (mood == 'sleepy' && !cap) {
    b.write('<text x="112" y="30" font-family="sans-serif" font-size="14" font-weight="700" fill="$_ink">z</text>');
  }
  b.write('</svg>');
  final out = b.toString();
  _cache[key] = out;
  return out;
}

/// The little Nimbus cloud mark used on card backs and the stage.
const kLogoSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 52" width="64" height="52">'
    '<path d="M16 46 A12 12 0 0 1 15 22 A16 16 0 0 1 46 19 A11 11 0 0 1 45 46 Z" fill="#fff" stroke="#1D2352" stroke-width="3"/>'
    '<circle cx="25" cy="33" r="2.6" fill="#1D2352"/><circle cx="37" cy="33" r="2.6" fill="#1D2352"/>'
    '<path d="M28 38 q3 3 6 0" stroke="#1D2352" stroke-width="2.2" fill="none" stroke-linecap="round"/></svg>';

// ───────── widgets ─────────

const _silhouette = ColorFilter.mode(Color(0x221D2352), BlendMode.srcIn);

class Critter extends StatelessWidget {
  const Critter(this.id, {super.key, this.size = 96, this.mood = 'happy', this.silhouette = false, this.shadow = true});
  final String id;
  final double size;
  final String mood;
  final bool silhouette;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final s = kSvc[id];
    final label = silhouette ? 'Undiscovered Cloudling' : (s == null ? 'Cloudling' : '${s.nick}, the ${s.name} Cloudling');
    return SvgPicture.string(
      critterSvg(id, mood: mood, shadow: shadow && !silhouette),
      width: size,
      height: size,
      colorFilter: silhouette ? _silhouette : null,
      semanticsLabel: label,
    );
  }
}

/// Puff the mascot, with a gentle random blink.
class Puff extends StatefulWidget {
  const Puff({super.key, this.size = 120, this.mood = 'happy', this.cap = false, this.glow = false, this.blink = true});
  final double size;
  final String mood;
  final bool cap;
  final bool glow;
  final bool blink;

  @override
  State<Puff> createState() => _PuffState();
}

class _PuffState extends State<Puff> {
  static final _r = math.Random();
  Timer? _t;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    if (widget.blink) _schedule();
  }

  void _schedule() {
    _t = Timer(Duration(milliseconds: 2600 + _r.nextInt(2600)), () {
      if (!mounted) return;
      setState(() => _closed = true);
      _t = Timer(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() => _closed = false);
        _schedule();
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    return SvgPicture.string(
      puffSvg(mood: widget.mood, cap: widget.cap, glow: widget.glow, blink: _closed),
      width: w,
      height: w * 120 / 140,
      semanticsLabel: 'Puff the cloud',
    );
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.width = 64});
  final double width;
  @override
  Widget build(BuildContext context) => SvgPicture.string(kLogoSvg, width: width, height: width * 52 / 64);
}
