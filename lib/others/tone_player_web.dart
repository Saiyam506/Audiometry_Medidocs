// ignore_for_file: deprecated_member_use
// ignore: uri_does_not_exist
import 'dart:html' as html;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

abstract class PtaTonePlayer {
  Future<void> playLoop(String frequency, {double volume = 0.2, double pan = 0.0});
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

PtaTonePlayer createPtaTonePlayer() => _WebOscillatorPtaTonePlayer();

Future<void> playTone(String freq) async {
  final player = createPtaTonePlayer();
  try {
    await player.playLoop(freq, volume: 0.35);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  } finally {
    await player.stop();
    await player.dispose();
  }
}

class _WebOscillatorPtaTonePlayer implements PtaTonePlayer {
  // Use dynamic + JS interop to access WebAudio APIs so analyzer doesn't
  // complain when running non-web analysis tools.
  dynamic _ctx;
  dynamic _osc;
  dynamic _gain;
  dynamic _panner;

  Future<void> _ensureContext() async {
    if (_ctx != null) return;
    try {
      final audioContextCtor = js_util.getProperty(html.window, 'AudioContext');
      if (audioContextCtor == null) return;
      _ctx = js_util.callConstructor(audioContextCtor, []);
      // attempt to resume (may require gesture)
      try {
        js_util.callMethod(_ctx, 'resume', []);
      } catch (_) {}
    } catch (_) {}
  }

  @override
  Future<void> playLoop(String frequency, {double volume = 0.2, double pan = 0.0}) async {
    await stop();
    await _ensureContext();
    if (_ctx == null) return;
    final freqVal = double.tryParse(frequency) ?? 1000.0;
    try {
      _gain = js_util.callMethod(_ctx, 'createGain', []);
      // Attempt to set the gain value in a couple of safe ways. Some
      // browsers expose the AudioParam as a getter-only property, so
      // directly setting `_gain.gain` can fail — avoid that and try
      // setting the `value` or calling `setValueAtTime` instead.
      try {
        final gainParam = js_util.getProperty(_gain, 'gain');
        if (gainParam != null) {
          try {
            js_util.setProperty(gainParam, 'value', volume.clamp(0.0, 1.0));
          } catch (_) {
            try {
              js_util.callMethod(gainParam, 'setValueAtTime', [volume.clamp(0.0, 1.0), js_util.getProperty(_ctx, 'currentTime')]);
            } catch (_) {}
          }
        }
      } catch (_) {}

      _osc = js_util.callMethod(_ctx, 'createOscillator', []);
      try {
        js_util.setProperty(_osc, 'type', 'sine');
        js_util.setProperty(js_util.getProperty(_osc, 'frequency'), 'value', freqVal);
      } catch (_) {}

      // create stereo panner if available and set pan value
      try {
        _panner = js_util.callMethod(_ctx, 'createStereoPanner', []);
        final panParam = js_util.getProperty(_panner, 'pan');
        if (panParam != null) {
          try {
            js_util.setProperty(panParam, 'value', pan.clamp(-1.0, 1.0));
          } catch (_) {
            try {
              js_util.callMethod(panParam, 'setValueAtTime', [pan.clamp(-1.0, 1.0), js_util.getProperty(_ctx, 'currentTime')]);
            } catch (_) {}
          }
        }
      } catch (_) {
        _panner = null;
      }

      // connect oscillator -> gain -> (panner?) -> destination
      try {
        if (_panner != null) {
          js_util.callMethod(_osc, 'connect', [_gain]);
          js_util.callMethod(_gain, 'connect', [_panner]);
          js_util.callMethod(_panner, 'connect', [js_util.getProperty(_ctx, 'destination')]);
        } else {
          js_util.callMethod(_osc, 'connect', [_gain]);
          js_util.callMethod(_gain, 'connect', [js_util.getProperty(_ctx, 'destination')]);
        }
      } catch (_) {}

      try {
        js_util.callMethod(_osc, 'start', [0]);
      } catch (_) {}
      html.window.console.log('WebOscillatorPtaTonePlayer: started $freqVal Hz');
    } catch (e) {
      html.window.console.warn('WebOscillatorPtaTonePlayer: failed to start oscillator -> $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final g = js_util.getProperty(_gain, 'gain');
      js_util.setProperty(g, 'value', volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      if (_osc != null) js_util.callMethod(_osc, 'stop', []);
    } catch (_) {}
    try {
      if (_osc != null) js_util.callMethod(_osc, 'disconnect', []);
    } catch (_) {}
    try {
      if (_gain != null) js_util.callMethod(_gain, 'disconnect', []);
    } catch (_) {}
    try {
      if (_panner != null) js_util.callMethod(_panner, 'disconnect', []);
    } catch (_) {}
    _osc = null;
    _gain = null;
    _panner = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      if (_ctx != null) js_util.callMethod(_ctx, 'close', []);
    } catch (_) {}
    _ctx = null;
  }
}

/// Ensure the web audio context is resumed (no-op on non-web platforms).
Future<void> ensureAudioEnabled() async {
  try {
    final ctor = js_util.getProperty(html.window, 'AudioContext') ?? js_util.getProperty(html.window, 'webkitAudioContext');
    if (ctor == null) return;
    final ctx = js_util.callConstructor(ctor, []);
    try {
      js_util.callMethod(ctx, 'resume', []);
    } catch (_) {}
  } catch (_) {}
}
