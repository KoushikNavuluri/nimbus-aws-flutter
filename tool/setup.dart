// One-time setup after cloning:   dart run tool/setup.dart
//
// 1. Generates the platform folders (android/ ios/ web/) for YOUR Flutter version.
// 2. Renames the app to "Nimbus" and sets its colours.
// 3. Draws Puff into a 1024px launcher icon (pure Dart, no image tools needed).
// 4. Gets packages and generates launcher icons.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show ByteData, BytesBuilder, Uint8List;

Future<void> main() async {
  stdout.writeln('Setting up Nimbus...');
  final missing = ['android', 'ios', 'web'].where((d) => !Directory(d).existsSync()).toList();
  if (missing.isNotEmpty) {
    await _run('flutter', ['create', '.', '--project-name', 'nimbus', '--org', 'dev.koushik', '--platforms=android,ios,web']);
  }
  _dropTemplateTest();
  _patch('android/app/src/main/AndroidManifest.xml',
      (s) => s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Nimbus"'));
  _patch('ios/Runner/Info.plist', (s) => s.replaceAllMapped(
      RegExp(r'(<key>CFBundle(Display)?Name</key>\s*<string>)[^<]*(</string>)'), (m) => '${m[1]}Nimbus${m[3]}'));
  _patch('web/index.html', (s) => s
      .replaceFirst(RegExp(r'<title>[^<]*</title>'), '<title>Nimbus \u00b7 Fall for the cloud</title>')
      .replaceAll('A new Flutter project.', 'Nimbus: a cute, interactive AWS learning playground.'));
  _patch('web/manifest.json', (s) {
    final m = jsonDecode(s) as Map<String, dynamic>;
    m['name'] = 'Nimbus \u00b7 Fall for the cloud';
    m['short_name'] = 'Nimbus';
    m['background_color'] = '#E7EEFF';
    m['theme_color'] = '#FF4D7E';
    m['description'] = 'A cute, interactive AWS learning playground.';
    return const JsonEncoder.withIndent('  ').convert(m);
  });
  _icon();
  await _run('flutter', ['pub', 'get']);
  if (File('assets/icon/icon.png').existsSync()) {
    await _run('dart', ['run', 'flutter_launcher_icons'], mustPass: false);
  }
  stdout.writeln('\nDone. Start Nimbus with:  flutter run');
}

/// `flutter create .` drops in the counter-app smoke test, which pumps `MyApp`.
/// Nimbus has no MyApp (it ships its own tests), so that file would break analyze and test.
void _dropTemplateTest() {
  final stub = File('test/widget_test.dart');
  if (!stub.existsSync()) return;
  final entry = File('lib/main.dart');
  final hasMyApp = entry.existsSync() && entry.readAsStringSync().contains('class MyApp');
  if (stub.readAsStringSync().contains('MyApp') && !hasMyApp) {
    stub.deleteSync();
    stdout.writeln('  removed the template test/widget_test.dart');
  }
}

Future<void> _run(String cmd, List<String> args, {bool mustPass = true}) async {
  stdout.writeln('\$ $cmd ${args.join(' ')}');
  final p = await Process.start(cmd, args, runInShell: true, mode: ProcessStartMode.inheritStdio);
  final code = await p.exitCode;
  if (code != 0 && mustPass) {
    stderr.writeln('Command failed ($code): $cmd ${args.join(' ')}');
    exit(code);
  }
}

void _patch(String path, String Function(String) change) {
  final file = File(path);
  if (!file.existsSync()) return;
  file.writeAsStringSync(change(file.readAsStringSync()));
}

// ───────── launcher icon: Puff, rasterised with 4x supersampling ─────────
void _icon() {
  final icon = File('assets/icon/icon.png');
  if (icon.existsSync()) return;
  Directory('assets/icon').createSync(recursive: true);
  icon.writeAsBytesSync(_png(1024, _puff(1024, 0.80, true)));
  File('assets/icon/icon_fg.png').writeAsBytesSync(_png(1024, _puff(1024, 0.56, false)));
  stdout.writeln('  drew Puff into assets/icon/');
}

class _Shape {
  _Shape(this.inside, this.r, this.g, this.b, [this.a = 1.0]);
  final bool Function(double x, double y) inside;
  final int r, g, b;
  final double a;
}

bool _circle(double x, double y, double cx, double cy, double r) => (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r;

bool _ellipse(double x, double y, double cx, double cy, double rx, double ry) {
  final dx = (x - cx) / rx, dy = (y - cy) / ry;
  return dx * dx + dy * dy <= 1;
}

bool _rrect(double x, double y, double l, double t, double w, double h, double r) {
  if (x < l || x > l + w || y < t || y > t + h) return false;
  final cx = x < l + r ? l + r : (x > l + w - r ? l + w - r : x);
  final cy = y < t + r ? t + r : (y > t + h - r ? t + h - r : y);
  return _circle(x, y, cx, cy, r);
}

Uint8List _puff(int size, double scale, bool background) {
  final k = size * scale / 140;
  final ox = (size - 140 * k) / 2;
  final oy = (size - 120 * k) / 2 + size * 0.02;
  const blobs = [
    [70.0, 62.0, 31.0], [42.0, 74.0, 21.0], [98.0, 74.0, 21.0],
    [54.0, 49.0, 20.0], [87.0, 51.0, 18.0], [70.0, 84.0, 24.0],
  ];
  final smile = <List<double>>[];
  for (var i = 0; i <= 40; i++) {
    final t = i / 40;
    final x = (1 - t) * (1 - t) * 63.48 + 2 * (1 - t) * t * 70.0 + t * t * 76.53;
    final y = (1 - t) * (1 - t) * 79.43 + 2 * (1 - t) * t * 86.1 + t * t * 79.43;
    smile.add([x, y]);
  }
  bool onSmile(double x, double y) {
    if (x < 61 || x > 79 || y < 77 || y > 86) return false;
    for (final p in smile) {
      if ((x - p[0]) * (x - p[0]) + (y - p[1]) * (y - p[1]) <= 3.3) return true;
    }
    return false;
  }

  final shapes = <_Shape>[
    _Shape((x, y) => blobs.any((b) => _circle(x, y, b[0], b[1], b[2] + 3)) || _rrect(x, y, 31, 70, 78, 31, 15), 0x1D, 0x23, 0x52),
    _Shape((x, y) => blobs.any((b) => _circle(x, y, b[0], b[1], b[2])) || _rrect(x, y, 34, 73, 72, 25, 12.5), 255, 255, 255),
    _Shape((x, y) => _ellipse(x, y, 70, 92, 30, 5), 0xE2, 0xE9, 0xFF),
    _Shape((x, y) => _ellipse(x, y, 54.05, 70, 5.65, 7.1) || _ellipse(x, y, 85.95, 70, 5.65, 7.1), 0x1D, 0x23, 0x52),
    _Shape((x, y) => _circle(x, y, 55.93, 67.25, 2.18) || _circle(x, y, 87.83, 67.25, 2.18), 255, 255, 255),
    _Shape((x, y) => _ellipse(x, y, 44.63, 80.15, 6.67, 3.92) || _ellipse(x, y, 95.38, 80.15, 6.67, 3.92), 0xFF, 0x7F, 0xA6, 0.55),
    _Shape(onSmile, 0x1D, 0x23, 0x52),
  ];
  final out = Uint8List(size * size * 4);
  const sub = [0.125, 0.375, 0.625, 0.875];
  for (var j = 0; j < size; j++) {
    for (var i = 0; i < size; i++) {
      var sr = 0.0, sg = 0.0, sb = 0.0, sa = 0.0;
      for (final dy in sub) {
        for (final dx in sub) {
          final x = (i + dx - ox) / k;
          final y = (j + dy - oy) / k;
          var r = background ? 0xE7 : 0, g = background ? 0xEE : 0, b = background ? 0xFF : 0;
          var a = background ? 1.0 : 0.0;
          if (x >= 0 && x <= 140 && y >= 0 && y <= 120) {
            for (final s in shapes) {
              if (!s.inside(x, y)) continue;
              r = (r * (1 - s.a) + s.r * s.a).round();
              g = (g * (1 - s.a) + s.g * s.a).round();
              b = (b * (1 - s.a) + s.b * s.a).round();
              a = a + s.a * (1 - a);
            }
          }
          sr += r * a;
          sg += g * a;
          sb += b * a;
          sa += a;
        }
      }
      final o = (j * size + i) * 4;
      if (sa > 0) {
        out[o] = (sr / sa).round().clamp(0, 255).toInt();
        out[o + 1] = (sg / sa).round().clamp(0, 255).toInt();
        out[o + 2] = (sb / sa).round().clamp(0, 255).toInt();
      }
      out[o + 3] = (sa / 16 * 255).round().clamp(0, 255).toInt();
    }
  }
  return out;
}

List<int> _png(int size, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < size; y++) {
    raw.addByte(0);
    raw.add(Uint8List.sublistView(rgba, y * size * 4, (y + 1) * size * 4));
  }
  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length);
    out.add(len.buffer.asUint8List());
    final typed = <int>[...ascii.encode(type), ...data];
    out.add(typed);
    final crc = ByteData(4)..setUint32(0, _crc32(typed));
    out.add(crc.buffer.asUint8List());
  }

  final ihdr = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', zlib.encode(raw.takeBytes()));
  chunk('IEND', const <int>[]);
  return out.takeBytes();
}

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final byte in data) {
    c ^= byte;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
