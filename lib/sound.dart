import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Tiny synthesized UI sounds (no audio files): pops, chimes, a paper tear.
/// Every sound is generated once from sine/triangle/saw tones into a WAV in memory.
class Sfx {
  Sfx._();
  static bool enabled = true;
  static const int sampleRate = 22050;
  static final Map<String, Uint8List> _cache = {};
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;

  static void play(String name) {
    if (name != 'tap') _haptic(name);
    if (!enabled) return;
    _play(name);
  }

  static Future<void> _play(String name) async {
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer());
        }
      }
      final player = _pool[_next++ % _pool.length];
      final bytes = _cache.putIfAbsent(name, () => _synth(name));
      await player.stop();
      await player.play(BytesSource(bytes), volume: 0.7);
    } catch (_) {
      // Audio unavailable on this platform: stay silent.
    }
  }

  static void _haptic(String name) {
    try {
      if (name == 'wrong') {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  static Uint8List _synth(String name) {
    final spec = _specs[name] ?? _specs['tap']!;
    final n = (spec.dur * sampleRate).round();
    final buf = Float64List(n);
    for (final e in spec.events) {
      e.render(buf);
    }
    var peak = 1e-6;
    for (final v in buf) {
      if (v.abs() > peak) peak = v.abs();
    }
    final k = 0.45 / peak;
    final data = ByteData(44 + n * 2);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = (buf[i] * k).clamp(-1.0, 1.0).toDouble();
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  static final Map<String, _Spec> _specs = {
    'tap': _Spec([_Tone(620, 0, .06, gain: .03, to: 820)], .08),
    'pop': _Spec([_Tone(520, 0, .12, gain: .05, to: 980)], .14),
    'flip': _Spec([_Tone(380, 0, .14, kind: 'triangle', gain: .04, to: 760)], .16),
    'tear': _Spec([_Noise(0, .32, .07)], .34),
    'correct': _Spec([_Tone(784, 0, .12), _Tone(1175, .09, .18)], .3),
    'wrong': _Spec([_Tone(240, 0, .18, kind: 'triangle', gain: .05, to: 180)], .2),
    'sparkle': _Spec([
      for (var i = 0; i < 4; i++) _Tone(const [1568.0, 2093.0, 2637.0, 3136.0][i], i * .06, .18, kind: 'triangle', gain: .025),
    ], .42),
    'win': _Spec([
      for (var i = 0; i < 4; i++) _Tone(const [523.0, 659.0, 784.0, 1047.0][i], i * .08, .22, gain: .05),
    ], .48),
    'whoosh': _Spec([_Tone(200, 0, .3, kind: 'saw', gain: .015, to: 60)], .32),
  };
}

class _Spec {
  const _Spec(this.events, this.dur);
  final List<_Event> events;
  final double dur;
}

abstract class _Event {
  const _Event();
  void render(Float64List buf);
}

class _Tone extends _Event {
  const _Tone(this.freq, this.start, this.dur, {this.kind = 'sine', this.gain = .06, this.to});
  final double freq, start, dur, gain;
  final double? to;
  final String kind;

  @override
  void render(Float64List buf) {
    const sr = Sfx.sampleRate;
    final s0 = (start * sr).round();
    final n = (dur * sr).round();
    const attack = 0.012;
    final end = to;
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      final double fr = end != null ? freq * math.pow(end / freq, t / dur).toDouble() : freq;
      phase += 2 * math.pi * fr / sr;
      final x = (phase % (2 * math.pi)) / (2 * math.pi);
      final double v;
      if (kind == 'triangle') {
        v = 2 * (2 * x - 1).abs() - 1;
      } else if (kind == 'saw') {
        v = 2 * x - 1;
      } else {
        v = math.sin(phase);
      }
      final double env = t < attack
          ? 0.0001 * math.pow(gain / 0.0001, t / attack).toDouble()
          : gain * math.pow(0.0001 / gain, (t - attack) / math.max(1e-6, dur - attack)).toDouble();
      final j = s0 + i;
      if (j < buf.length) buf[j] += v * env;
    }
  }
}

class _Noise extends _Event {
  const _Noise(this.start, this.dur, this.gain);
  final double start, dur, gain;

  @override
  void render(Float64List buf) {
    const sr = Sfx.sampleRate;
    final rnd = math.Random(7);
    final s0 = (start * sr).round();
    final n = (dur * sr).round();
    const rc = 1 / (2 * math.pi * 1800);
    const dt = 1 / sr;
    const a = rc / (rc + dt);
    var px = 0.0, py = 0.0;
    for (var i = 0; i < n; i++) {
      final x = (rnd.nextDouble() * 2 - 1) * (1 - i / n);
      final y = a * (py + x - px);
      px = x;
      py = y;
      final j = s0 + i;
      if (j < buf.length) buf[j] += y * gain;
    }
  }
}
