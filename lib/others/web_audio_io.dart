import 'dart:async';

Future<bool> playWebAudio(String assetPath, {double pan = 0.0}) async {
  // Non-web stub: log for diagnostics in debug/dev environments.
  // The native AudioPlayer path should be used on non-web platforms.
  try {
    // ignore: avoid_print
    print('playWebAudio (non-web stub) called for: $assetPath');
  } catch (_) {}
  return false;
}
