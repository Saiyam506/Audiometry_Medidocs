abstract class PtaTonePlayer {
  Future<void> playLoop(String frequency, {double volume = 0.2, double pan = 0.0});
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

PtaTonePlayer createPtaTonePlayer() => _NoopPtaTonePlayer();

class _NoopPtaTonePlayer implements PtaTonePlayer {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playLoop(String frequency, {double volume = 0.2, double pan = 0.0}) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}

Future<void> ensureAudioEnabled() async {}
