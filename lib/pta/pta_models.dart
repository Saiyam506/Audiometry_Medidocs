enum PtaPhase { idle, countdown, testing, transitioning, completed }

class PtaStep {
  final String ear;
  final int frequency;

  const PtaStep({required this.ear, required this.frequency});

  String get key => '$ear-$frequency';
  String get label => '$ear Ear';
  String get frequencyLabel => '$frequency Hz';
}

class FrequencyResult {
  final String ear;
  final int frequency;
  final double responseTime;
  final double detectedDb;
  final int score;
  final bool heard;
  final DateTime timestamp;

  const FrequencyResult({
    required this.ear,
    required this.frequency,
    required this.responseTime,
    required this.detectedDb,
    required this.score,
    required this.heard,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'ear': ear,
    'frequency': frequency,
    'responseTime': responseTime,
    'detectedDb': detectedDb,
    'score': score,
    'heard': heard,
    'timestamp': timestamp.toIso8601String(),
  };
}
