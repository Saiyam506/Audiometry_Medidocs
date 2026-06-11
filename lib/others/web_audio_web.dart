// ignore_for_file: deprecated_member_use
// ignore: uri_does_not_exist
import 'dart:html' as html;
import 'dart:async';
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

html.AudioElement? _current;

String _replaceFilename(String path, String newName) {
  final parts = path.split('/');
  if (parts.isEmpty) return path;
  parts[parts.length - 1] = newName;
  return parts.join('/');
}

Future<bool> playWebAudio(String assetPath, {double pan = 0.0}) async {
  // Build candidate URLs: original, lowercase filename, alt extensions
  try {
    final uri = Uri.parse(assetPath);
    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      html.window.console.log('playWebAudio: empty path: $assetPath');
      return false;
    }

    final filename = segments.last;
    final base = filename.replaceAll(RegExp(r'\.(mp3|wav)$', caseSensitive: false), '');
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    final altExt = ext == 'mp3' ? 'wav' : 'mp3';

    final candidates = <String>{};
    candidates.add(assetPath);
    // lower/upper filename variants
    candidates.add(_replaceFilename(assetPath, filename.toLowerCase()));
    candidates.add(_replaceFilename(assetPath, filename.toUpperCase()));
    // try alternate extension with same case
    if (ext.isNotEmpty) {
      candidates.add(_replaceFilename(assetPath, '$base.$altExt'));
      candidates.add(_replaceFilename(assetPath, '${base.toLowerCase()}.$altExt'));
      candidates.add(_replaceFilename(assetPath, '${base.toUpperCase()}.$altExt'));
    }

    // Try all candidates until one plays
    for (final candidate in candidates) {
      try {
        final audio = html.AudioElement();
        audio.preload = 'auto';
        audio.controls = false;
        audio.loop = false;
        audio.src = candidate;

        // Quick canPlayType check
        final canPlay = audio.canPlayType(ext == 'mp3' ? 'audio/mpeg' : 'audio/wav');
        html.window.console.log('playWebAudio: trying $candidate canPlayType=$canPlay');

        // attach to global so stop() can find it
        _current?.pause();
        _current = audio;

        // If a pan value is requested and the browser supports WebAudio,
        // route the audio element through an AudioContext + StereoPannerNode.
        if (pan != 0.0) {
          try {
            final audioContextCtor = js_util.getProperty(html.window, 'AudioContext') ?? js_util.getProperty(html.window, 'webkitAudioContext');
            if (audioContextCtor != null) {
              final ctx = js_util.callConstructor(audioContextCtor, []);
              final src = js_util.callMethod(ctx, 'createMediaElementSource', [audio]);
              final panner = js_util.callMethod(ctx, 'createStereoPanner', []);
              final panParam = js_util.getProperty(panner, 'pan');
              if (panParam != null) {
                try {
                  js_util.setProperty(panParam, 'value', pan.clamp(-1.0, 1.0));
                } catch (_) {
                  try {
                    js_util.callMethod(panParam, 'setValueAtTime', [pan.clamp(-1.0, 1.0), js_util.getProperty(ctx, 'currentTime')]);
                  } catch (_) {}
                }
              }
              js_util.callMethod(src, 'connect', [panner]);
              js_util.callMethod(panner, 'connect', [js_util.getProperty(ctx, 'destination')]);
            }
          } catch (e) {
            html.window.console.warn('playWebAudio: panner setup failed -> $e');
          }
        }

        // Attempt to play; if it fails, try next candidate
        await audio.play();
        html.window.console.log('playWebAudio: started $candidate');
        return true;
      } catch (e) {
        html.window.console.warn('playWebAudio: failed candidate $candidate -> $e');
        // try next
      }
    }
    html.window.console.error('playWebAudio: all candidates failed for $assetPath');
    return false;
  } catch (e) {
    html.window.console.error('playWebAudio: unexpected error for $assetPath -> $e');
    return false;
  }
}
