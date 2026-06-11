import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../pta/pta_models.dart';
import 'package:flutter/services.dart';

const Color _ptaSurface = Color(0xFFF8FBFF);
const Color _ptaBorder = Color(0xFFD6E4F2);
const Color _ptaInk = Color(0xFF16324F);
const Color _ptaMuted = Color(0xFF6D7F95);
const Color _ptaAccent = Color(0xFF2AA7A1);
const Color _ptaAccentStrong = Color(0xFF0B7A75);
const Color _ptaWarn = Color(0xFFFFB25B);
const Color _ptaSuccess = Color(0xFF2EAA6A);
const Color _ptaDanger = Color(0xFFE46B6B);

class PtaGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const PtaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: _ptaBorder.withAlpha(((0.8) * 255).round())),
        gradient: LinearGradient(
          colors: [
            _ptaSurface,
            Color(0xFFF3FAFF).withAlpha(((0.96) * 255).round()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7EA6C9).withAlpha(((0.12) * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PtaSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const PtaSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: _ptaInk,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 6.sp, height: 1.3, color: _ptaMuted),
        ),
      ],
    );
  }
}

class PtaIntroCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onStart;
  final int completedCount;
  final int totalCount;

  const PtaIntroCard({
    super.key,
    required this.busy,
    required this.onStart,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return PtaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2AA7A1), Color(0xFF6ED3C4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hearing, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guided PTA',
                      style: TextStyle(
                        fontSize: 6.sp,
                        fontWeight: FontWeight.w800,
                        color: _ptaInk,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'A clean, fully guided hearing test with one tone at a time.',
                      style: TextStyle(fontSize: 4.sp, color: _ptaMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Center(
            child: Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                _PtaMiniStat(
                  label: 'Steps',
                  value: '$completedCount / $totalCount',
                  icon: Icons.route,
                  fontSize: 6.sp,
                  valueFontSize: 4.sp,
                ),
                _PtaMiniStat(
                  label: 'Behavior',
                  value: 'Auto-advance',
                  icon: Icons.skip_next,
                  fontSize: 6.sp,
                  valueFontSize: 4.sp,
                ),
                _PtaMiniStat(
                  label: 'Timer',
                  value: '10 s max',
                  icon: Icons.timer_outlined,
                  fontSize: 6.sp,
                  valueFontSize: 4.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _PtaInstructionList(
            items: const [
              'Left ear first, then right ear.',
              'Watch the dB meter as the tone grows louder.',
              'Tap I CAN HEAR as soon as you detect the tone.',
              'The app records response time, score, and detected dB.',
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: _PtaActionButton(
              enabled: !busy,
              label: busy ? 'Starting...' : 'Start guided PTA',
              icon: Icons.play_arrow_rounded,
              accent: _ptaAccentStrong,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class PtaSessionHeader extends StatelessWidget {
  final String ear;
  final int frequency;
  final String stepLabel;
  final String phaseLabel;
  final double progress;

  const PtaSessionHeader({
    super.key,
    required this.ear,
    required this.frequency,
    required this.stepLabel,
    required this.phaseLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return PtaGlassCard(
      padding: EdgeInsets.all(7.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PtaInfoChip(
                icon: Icons.hearing,
                label: ear,
                accent: _ptaAccentStrong,
              ),
              SizedBox(width: 6.w),
              _PtaInfoChip(
                icon: Icons.graphic_eq_rounded,
                label: '$frequency Hz',
                accent: _ptaAccent,
              ),
              const Spacer(),
              _PtaInfoChip(
                icon: Icons.timelapse_rounded,
                label: phaseLabel,
                accent: _ptaWarn,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: _ptaInk,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: _ptaMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE4EEF7),
              valueColor: const AlwaysStoppedAnimation<Color>(_ptaAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class PtaLiveVisualCard extends StatelessWidget {
  final String ear;
  final int frequency;
  final double db;
  final double elapsedSeconds;
  final int countdownSeconds;
  final bool testing;
  final bool active;

  const PtaLiveVisualCard({
    super.key,
    required this.ear,
    required this.frequency,
    required this.db,
    required this.elapsedSeconds,
    required this.countdownSeconds,
    required this.testing,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (10.0 - elapsedSeconds).clamp(0.0, 10.0);
    final titleText = !active
        ? 'PTA test completed'
        : (testing ? 'Tone in progress' : 'Preparing the next tone');
    final statusText = !active
        ? 'All tones have been tested.'
        : (countdownSeconds > 0
              ? 'Countdown: $countdownSeconds'
              : 'Timer: ${remaining.toStringAsFixed(1)} s left');
    return PtaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: _ptaInk,
                  ),
                ),
              ),
              _PtaEarGlyph(ear: ear),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF2FAF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ptaBorder),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: _ptaAccentStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PtaHearButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const PtaHearButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _ptaAccent.withAlpha(((0.28) * 255).round()),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (enabled) {
                HapticFeedback.mediumImpact();
                onPressed();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ptaAccentStrong,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'I CAN HEAR',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PtaSensitivityChart extends StatelessWidget {
  final List<PtaStep> steps;
  final FrequencyResult? Function(String ear, int frequency) resultFor;
  final int averageScore;
  final double averageDb;

  const PtaSensitivityChart({
    super.key,
    required this.steps,
    required this.resultFor,
    required this.averageScore,
    required this.averageDb,
  });

  @override
  Widget build(BuildContext context) {
    final leftSteps = steps.where((step) => step.ear == 'Left').toList();
    final rightSteps = steps.where((step) => step.ear == 'Right').toList();

    return PtaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PtaSectionTitle(
            title: 'Hearing sensitivity chart',
            subtitle:
                'Compact overview of response time, detected dB, and score for each frequency.',
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _PtaChartSummary(
                label: 'Average score',
                value: '$averageScore',
                accent: _ptaAccentStrong,
              ),
              _PtaChartSummary(
                label: 'Average dB',
                value: averageDb.toStringAsFixed(0),
                accent: _ptaWarn,
              ),
              _PtaChartSummary(
                label: 'Recorded',
                value:
                    '${steps.where((step) => resultFor(step.ear, step.frequency) != null).length}/${steps.length}',
                accent: _ptaSuccess,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _PtaEarChart(
            title: 'Left ear',
            steps: leftSteps,
            resultFor: resultFor,
          ),
          SizedBox(height: 12.h),
          _PtaEarChart(
            title: 'Right ear',
            steps: rightSteps,
            resultFor: resultFor,
          ),
        ],
      ),
    );
  }
}

class PtaSessionRecap extends StatelessWidget {
  final FrequencyResult? latestResult;
  final VoidCallback onRestart;
  final bool busy;

  const PtaSessionRecap({
    super.key,
    required this.latestResult,
    required this.onRestart,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final result = latestResult;
    return PtaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PtaSectionTitle(
            title: 'Session recap',
            subtitle:
                'The last response is captured with timestamp, response time, and detected dB.',
          ),
          SizedBox(height: 14.h),
          if (result == null)
            Text(
              'No guided PTA result yet. Start the assessment to generate the full frequency map.',
              style: TextStyle(fontSize: 13.sp, color: _ptaMuted),
            )
          else
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _PtaRecapCard(
                  label: 'Ear',
                  value: result.ear,
                  accent: _ptaAccentStrong,
                ),
                _PtaRecapCard(
                  label: 'Frequency',
                  value: '${result.frequency} Hz',
                  accent: _ptaAccent,
                ),
                _PtaRecapCard(
                  label: 'Response',
                  value: '${result.responseTime.toStringAsFixed(1)} s',
                  accent: _ptaWarn,
                ),
                _PtaRecapCard(
                  label: 'Detected',
                  value: '${result.detectedDb.toStringAsFixed(0)} dB',
                  accent: result.heard ? _ptaSuccess : _ptaDanger,
                ),
                _PtaRecapCard(
                  label: 'Score',
                  value: '${result.score}',
                  accent: _ptaAccentStrong,
                ),
              ],
            ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: _PtaActionButton(
              enabled: !busy,
              label: busy ? 'Preparing...' : 'Run again',
              icon: Icons.restart_alt_rounded,
              accent: _ptaAccentStrong,
              onPressed: onRestart,
            ),
          ),
        ],
      ),
    );
  }
}

class _PtaInstructionList extends StatelessWidget {
  final List<String> items;

  const _PtaInstructionList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                margin: EdgeInsets.only(top: 2.h),
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F5F3),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w800,
                    color: _ptaAccentStrong,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 1.h, bottom: 12.h),
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 7.sp,
                      height: 1.45,
                      color: _ptaInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PtaMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? fontSize;
  final double? valueFontSize;

  const _PtaMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.fontSize,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ptaBorder.withAlpha(((0.85) * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: _ptaAccentStrong),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: fontSize ?? 11.sp, color: _ptaMuted),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize:
                      valueFontSize ??
                      (fontSize != null ? (fontSize! + 2.sp) : 13.sp),
                  fontWeight: FontWeight.w800,
                  color: _ptaInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PtaInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _PtaInfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accent.withAlpha(((0.1) * 255).round()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: accent),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: _ptaInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PtaEarGlyph extends StatelessWidget {
  final String ear;

  const _PtaEarGlyph({required this.ear});

  @override
  Widget build(BuildContext context) {
    final isLeft = ear.toLowerCase().contains('left');
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F4F3), Color(0xFFCDEEE9)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isLeft ? Icons.hearing_rounded : Icons.hearing,
        color: _ptaAccentStrong,
        size: 16.sp,
      ),
    );
  }
}

class PtaDbMeter extends StatelessWidget {
  final double level;

  const PtaDbMeter({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0.0, 1.0);
    return Container(
      height: (88.h).clamp(72.0, 110.0),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.65) * 255).round()),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ptaBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'dB meter',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: _ptaInk,
            ),
          ),
          SizedBox(height: 5.h),
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final mark in [100, 80, 60, 40, 20, 0])
                      Text(
                        '$mark',
                        style: TextStyle(
                          fontSize: 6.sp,
                          color: _ptaMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFFEAF3F8),
                                const Color(0xFFFDFEFE),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: clamped,
                            widthFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF2AA7A1),
                                    Color(0xFF8DE2CF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PtaChartSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PtaChartSummary({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: accent.withAlpha(((0.12) * 255).round()),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: _ptaMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: _ptaInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PtaEarChart extends StatelessWidget {
  final String title;
  final List<PtaStep> steps;
  final FrequencyResult? Function(String ear, int frequency) resultFor;

  const _PtaEarChart({
    required this.title,
    required this.steps,
    required this.resultFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ptaBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: _ptaInk,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final step in steps)
                _PtaFrequencyTile(
                  result: resultFor(step.ear, step.frequency),
                  frequency: step.frequency,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PtaFrequencyTile extends StatelessWidget {
  final FrequencyResult? result;
  final int frequency;

  const _PtaFrequencyTile({required this.result, required this.frequency});

  @override
  Widget build(BuildContext context) {
    final heard = result?.heard ?? false;
    final score = result?.score ?? 0;
    final db = result?.detectedDb ?? 0.0;
    return Container(
      width: 92.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: heard ? Colors.white : const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: heard
              ? _ptaSuccess.withAlpha(((0.35) * 255).round())
              : _ptaBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$frequency Hz',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: _ptaInk,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFE6EEF6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (db / 100.0).clamp(0.08, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: heard
                        ? [const Color(0xFF2AA7A1), const Color(0xFF89E2D0)]
                        : [const Color(0xFFE4A3A3), const Color(0xFFF1C4C4)],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            heard ? '${db.round()} dB' : 'No response',
            style: TextStyle(fontSize: 9.sp, color: _ptaMuted),
          ),
          SizedBox(height: 2.h),
          Text(
            'Score $score',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: heard ? _ptaSuccess : _ptaDanger,
            ),
          ),
          if (result != null) ...[
            SizedBox(height: 4.h),
            Text(
              result!.timestamp.toLocal().toIso8601String().substring(11, 19),
              style: TextStyle(fontSize: 8.sp, color: _ptaMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _PtaRecapCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PtaRecapCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: accent.withAlpha(((0.12) * 255).round()),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(((0.2) * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              color: _ptaMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: _ptaInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PtaActionButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  const _PtaActionButton({
    required this.enabled,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.7,
      duration: const Duration(milliseconds: 180),
      child: ElevatedButton.icon(
        onPressed: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed();
              }
            : null,
        icon: Icon(icon, size: 14.sp),
        label: Text(
          label,
          style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 0 : 0,
        ),
      ),
    );
  }
}

class LandingWrsSection extends StatelessWidget {
  final bool isWide;
  final String language;
  final List<Map<String, dynamic>> wordBank;
  final Map<int, String?> wrsAnswers;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function(int) onPlayWord;
  final void Function(int id, String option) onWordSelected;

  const LandingWrsSection({
    super.key,
    required this.isWide,
    required this.language,
    required this.wordBank,
    required this.wrsAnswers,
    required this.onLanguageChanged,
    required this.onPlayWord,
    required this.onWordSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PtaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PtaSectionTitle(
            title: 'Word recognition test',
            subtitle:
                'Audio playback remains unchanged, but the section is compacted and visually aligned with the new PTA flow.',
          ),
          SizedBox(height: 10.h),
          LandingLanguageSelector(
            language: language,
            onChanged: onLanguageChanged,
          ),
          SizedBox(height: 10.h),
          if (isWide)
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: wordBank
                  .map(
                    (word) => SizedBox(
                      width: 280.w,
                      child: LandingWrsItem(
                        item: word,
                        wrsAnswers: wrsAnswers,
                        onPlayWord: onPlayWord,
                        onWordSelected: onWordSelected,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Column(
              children: wordBank
                  .map(
                    (word) => LandingWrsItem(
                      item: word,
                      wrsAnswers: wrsAnswers,
                      onPlayWord: onPlayWord,
                      onWordSelected: onWordSelected,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class LandingLanguageSelector extends StatelessWidget {
  final String language;
  final ValueChanged<String> onChanged;

  const LandingLanguageSelector({
    super.key,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Language',
          style: TextStyle(
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF16324F),
          ),
        ),
        DropdownButton<String>(
          value: language,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          items: const ['English', 'Hindi', 'Kannada', 'Telugu']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (value) => onChanged(value ?? language),
        ),
      ],
    );
  }
}

class LandingWrsItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<int, String?> wrsAnswers;
  final Future<void> Function(int) onPlayWord;
  final void Function(int id, String option) onWordSelected;

  const LandingWrsItem({
    super.key,
    required this.item,
    required this.wrsAnswers,
    required this.onPlayWord,
    required this.onWordSelected,
  });

  @override
  Widget build(BuildContext context) {
    final int id = item['id'] as int;
    final List<String> options = List<String>.from(item['options'] as List);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.82) * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Word: ${item['word']}',
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16324F),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                color: const Color(0xFF1E7B82),
                onPressed: () => onPlayWord(id),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option, style: TextStyle(fontSize: 7.sp)),
                    selected: wrsAnswers[id] == option,
                    onSelected: (_) => onWordSelected(id, option),
                    labelStyle: TextStyle(
                      color: wrsAnswers[id] == option
                          ? Colors.white
                          : const Color(0xFF16324F),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: const Color(0xFF1E7B82),
                    backgroundColor: const Color(0xFFF0F6FB),
                    side: BorderSide(color: Color(0xFFD3E0EA)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
