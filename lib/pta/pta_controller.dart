import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../others/tone_player.dart';
import 'pta_models.dart';

class PtaTestController extends GetxController {
  static const List<PtaStep> _steps = <PtaStep>[
    PtaStep(ear: 'Left', frequency: 500),
    PtaStep(ear: 'Left', frequency: 1000),
    PtaStep(ear: 'Left', frequency: 2000),
    PtaStep(ear: 'Left', frequency: 4000),
    PtaStep(ear: 'Right', frequency: 500),
    PtaStep(ear: 'Right', frequency: 1000),
    PtaStep(ear: 'Right', frequency: 2000),
    PtaStep(ear: 'Right', frequency: 4000),
  ];

  static const int _countdownStart = 5;
  static const double _toneDurationSeconds = 10.0;
  static const int _volumeRampTickMs = 100;

  final PtaTonePlayer _tonePlayer = createPtaTonePlayer();
  final RxList<FrequencyResult> results = <FrequencyResult>[].obs;
  final Rx<PtaPhase> phase = PtaPhase.idle.obs;
  final RxInt currentStepIndex = (-1).obs;
  final RxInt countdownSeconds = 0.obs;
  final RxDouble elapsedSeconds = 0.0.obs;
  final RxDouble currentDb = 0.0.obs;
  final RxDouble currentProgress = 0.0.obs;
  final RxString currentEar = 'Left'.obs;
  final RxInt currentFrequency = 500.obs;
  final RxInt currentScore = 0.obs;
  final Rxn<FrequencyResult> latestResult = Rxn<FrequencyResult>();

  Timer? _tickTimer;
  Timer? _timeoutTimer;
  Completer<FrequencyResult>? _stepCompleter;
  DateTime? _stepStartedAt;
  int _sessionToken = 0;

  List<PtaStep> get steps => _steps;
  int get totalSteps => _steps.length;
  bool get isIdle => phase.value == PtaPhase.idle;
  bool get isRunning =>
      phase.value == PtaPhase.countdown ||
      phase.value == PtaPhase.testing ||
      phase.value == PtaPhase.transitioning;
  bool get isTesting => phase.value == PtaPhase.testing;
  bool get canStart => !isTesting && phase.value != PtaPhase.countdown;
  int get completedCount => results.length;
  double get overallProgress {
    if (totalSteps == 0) {
      return 0.0;
    }
    if (phase.value == PtaPhase.countdown || phase.value == PtaPhase.testing) {
      final activeStep = currentStepIndex.value < 0
          ? 0
          : currentStepIndex.value;
      return ((activeStep + currentProgress.value) / totalSteps).clamp(
        0.0,
        1.0,
      );
    }
    return (results.length / totalSteps).clamp(0.0, 1.0);
  }

  String get phaseLabel {
    switch (phase.value) {
      case PtaPhase.idle:
        return 'Ready to begin';
      case PtaPhase.countdown:
        return 'Countdown';
      case PtaPhase.testing:
        return 'Tone running';
      case PtaPhase.transitioning:
        return 'Moving to next frequency';
      case PtaPhase.completed:
        return 'Assessment complete';
    }
  }

  String get stepLabel => currentStepIndex.value < 0
      ? 'Step 0 of $totalSteps'
      : 'Step ${currentStepIndex.value + 1} of $totalSteps';

  PtaStep? get currentStep {
    if (currentStepIndex.value < 0 || currentStepIndex.value >= _steps.length) {
      return null;
    }
    return _steps[currentStepIndex.value];
  }

  Map<String, double> thresholdsForEar(String ear, {double fallback = 20.0}) {
    final map = <String, double>{
      '500': fallback,
      '1000': fallback,
      '2000': fallback,
      '4000': fallback,
    };
    for (final result in results.where((element) => element.ear == ear)) {
      map['${result.frequency}'] = result.detectedDb;
    }
    return map;
  }

  FrequencyResult? resultFor(String ear, int frequency) {
    for (final result in results) {
      if (result.ear == ear && result.frequency == frequency) {
        return result;
      }
    }
    return null;
  }

  double get averageScore {
    if (results.isEmpty) {
      return 0.0;
    }
    return results.map((result) => result.score).reduce((a, b) => a + b) /
        results.length;
  }

  double get averageDetectedDb {
    if (results.isEmpty) {
      return 0.0;
    }
    return results.map((result) => result.detectedDb).reduce((a, b) => a + b) /
        results.length;
  }

  Future<void> startGuidedAssessment() async {
    // Try to resume the web audio context immediately on the user's Start gesture.
    // Calling without awaiting helps ensure the resume is tied to the gesture.
    try {
      ensureAudioEnabled();
    } catch (_) {}

    await _stopActiveSession(clearState: true);
    final sessionToken = ++_sessionToken;

    phase.value = PtaPhase.countdown;
    currentStepIndex.value = -1;
    currentScore.value = 0;
    results.clear();
    latestResult.value = null;
    countdownSeconds.value = _countdownStart;
    elapsedSeconds.value = 0.0;
    currentDb.value = 0.0;
    currentProgress.value = 0.0;
    currentEar.value = _steps.first.ear;
    currentFrequency.value = _steps.first.frequency;

    for (var index = 0; index < _steps.length; index++) {
      if (!_isSessionActive(sessionToken)) {
        return;
      }
      currentStepIndex.value = index;
      final step = _steps[index];
      currentEar.value = step.ear;
      currentFrequency.value = step.frequency;

      await _runCountdown(sessionToken);
      if (!_isSessionActive(sessionToken)) {
        return;
      }

      phase.value = PtaPhase.testing;
      final result = await _runFrequencyStep(sessionToken, step);
      if (!_isSessionActive(sessionToken)) {
        return;
      }

      results.add(result);
      latestResult.value = result;
      currentScore.value = result.score;
      phase.value = index == _steps.length - 1
          ? PtaPhase.completed
          : PtaPhase.transitioning;
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }

    if (_isSessionActive(sessionToken)) {
      phase.value = PtaPhase.completed;
    }
  }

  Future<void> recordHeard() async {
    if (!isTesting || _stepCompleter == null || _stepCompleter!.isCompleted) {
      return;
    }
    final start = _stepStartedAt ?? DateTime.now();
    final responseTime = _elapsedSince(start);
    final result = _buildResult(
      heard: true,
      responseTime: responseTime,
      detectedDb: _dbForElapsed(responseTime),
      timestamp: DateTime.now(),
    );
    await _finishStep(result);
  }

  Future<void> restart() async {
    await startGuidedAssessment();
  }

  Future<void> cancel() async {
    await _stopActiveSession(clearState: true);
    results.clear();
    latestResult.value = null;
    phase.value = PtaPhase.idle;
  }

  @override
  void onClose() {
    _stopActiveSession(clearState: false);
    _tonePlayer.dispose();
    super.onClose();
  }

  Future<void> _runCountdown(int sessionToken) async {
    phase.value = PtaPhase.countdown;
    for (var remaining = _countdownStart; remaining > 0; remaining--) {
      if (!_isSessionActive(sessionToken)) {
        return;
      }
      countdownSeconds.value = remaining;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (_isSessionActive(sessionToken)) {
      countdownSeconds.value = 0;
    }
  }

  Future<FrequencyResult> _runFrequencyStep(
    int sessionToken,
    PtaStep step,
  ) async {
    await _stopToneTimers();
    final startedAt = DateTime.now();
    _stepStartedAt = startedAt;
    _stepCompleter = Completer<FrequencyResult>();
    elapsedSeconds.value = 0.0;
    currentProgress.value = 0.0;
    currentDb.value = 0.0;
    currentScore.value = 0;

    // Start the tone but don't await playback to avoid blocking the tick timer
    final pan = step.ear.toLowerCase().contains('left')
        ? -1.0
        : (step.ear.toLowerCase().contains('right') ? 1.0 : 0.0);
    unawaited(
      _tonePlayer.playLoop(step.frequency.toString(), volume: 0.08, pan: pan),
    );

    _tickTimer = Timer.periodic(
      const Duration(milliseconds: _volumeRampTickMs),
      (timer) {
        if (!_isSessionActive(sessionToken)) {
          timer.cancel();
          return;
        }
        final elapsed = _elapsedSince(
          startedAt,
        ).clamp(0.0, _toneDurationSeconds);
        elapsedSeconds.value = elapsed;
        currentProgress.value = (elapsed / _toneDurationSeconds).clamp(
          0.0,
          1.0,
        );
        currentDb.value = _dbForElapsed(elapsed);
        if (elapsed >= _toneDurationSeconds &&
            _stepCompleter != null &&
            !_stepCompleter!.isCompleted) {
          _stepCompleter!.complete(
            _buildResult(
              heard: false,
              responseTime: _toneDurationSeconds,
              detectedDb: 100.0,
              timestamp: DateTime.now(),
            ),
          );
        }
        unawaited(_tonePlayer.setVolume(_volumeForElapsed(elapsed)));
      },
    );

    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_stepCompleter != null && !_stepCompleter!.isCompleted) {
        _stepCompleter!.complete(
          _buildResult(
            heard: false,
            responseTime: _toneDurationSeconds,
            detectedDb: 100.0,
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    final result = await _stepCompleter!.future;
    await _stopToneTimers();
    await _tonePlayer.stop();
    currentDb.value = result.detectedDb;
    elapsedSeconds.value = result.responseTime;
    currentProgress.value = (result.responseTime / _toneDurationSeconds).clamp(
      0.0,
      1.0,
    );
    return result;
  }

  Future<void> _finishStep(FrequencyResult result) async {
    if (_stepCompleter == null || _stepCompleter!.isCompleted) {
      return;
    }
    _stepCompleter!.complete(result);
    currentDb.value = result.detectedDb;
    elapsedSeconds.value = result.responseTime;
    currentProgress.value = (result.responseTime / _toneDurationSeconds).clamp(
      0.0,
      1.0,
    );
    currentScore.value = result.score;
    unawaited(_tonePlayer.stop());
  }

  Future<void> _stopActiveSession({required bool clearState}) async {
    _sessionToken++;
    if (_stepCompleter != null && !_stepCompleter!.isCompleted) {
      _stepCompleter!.complete(
        _buildResult(
          heard: false,
          responseTime: elapsedSeconds.value,
          detectedDb: currentDb.value,
          timestamp: DateTime.now(),
        ),
      );
    }
    await _stopToneTimers();
    await _tonePlayer.stop();
    if (clearState) {
      _stepCompleter = null;
      _stepStartedAt = null;
      currentStepIndex.value = -1;
      currentDb.value = 0.0;
      currentProgress.value = 0.0;
      elapsedSeconds.value = 0.0;
      countdownSeconds.value = 0;
      currentScore.value = 0;
    }
  }

  Future<void> _stopToneTimers() async {
    _tickTimer?.cancel();
    _timeoutTimer?.cancel();
    _tickTimer = null;
    _timeoutTimer = null;
  }

  bool _isSessionActive(int sessionToken) => sessionToken == _sessionToken;

  double _elapsedSince(DateTime startedAt) {
    return DateTime.now().difference(startedAt).inMilliseconds / 1000.0;
  }

  double _dbForElapsed(double elapsedSecondsValue) {
    final value = elapsedSecondsValue.clamp(0.0, _toneDurationSeconds);
    return min(100.0, value * 10.0);
  }

  double _volumeForElapsed(double elapsedSecondsValue) {
    final db = _dbForElapsed(elapsedSecondsValue);
    return (0.08 + ((db / 100.0) * 0.92)).clamp(0.0, 1.0);
  }

  int _scoreFor(double responseTime) {
    if (responseTime <= 2.0) {
      return 100;
    }
    if (responseTime <= 4.0) {
      return 80;
    }
    if (responseTime <= 6.0) {
      return 60;
    }
    if (responseTime <= 8.0) {
      return 40;
    }
    if (responseTime <= 10.0) {
      return 20;
    }
    return 0;
  }

  FrequencyResult _buildResult({
    required bool heard,
    required double responseTime,
    required double detectedDb,
    required DateTime timestamp,
  }) {
    return FrequencyResult(
      ear: currentEar.value,
      frequency: currentFrequency.value,
      responseTime: responseTime.clamp(0.0, _toneDurationSeconds),
      detectedDb: detectedDb.clamp(0.0, 100.0),
      score: heard ? _scoreFor(responseTime) : 0,
      heard: heard,
      timestamp: timestamp,
    );
  }
}
