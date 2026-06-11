import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hearing_aid/landing_page/wrs_assessment/wrs_assessment.dart';

import '../../pta/pta_controller.dart';
import '../../pta/pta_models.dart';
import '../widgets.dart';
import 'mobile.dart' as hearing_mobile;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hearing_aid/others/report_opener_io.dart'
    if (dart.library.html) 'package:hearing_aid/others/report_opener_web.dart';

class HearingAssessmentPage extends StatefulWidget {
  const HearingAssessmentPage({super.key});

  @override
  State<HearingAssessmentPage> createState() => _HearingAssessmentPageState();
}

class HearingAssessmentResponsivePage extends StatelessWidget {
  const HearingAssessmentResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final useMobileLayout = MediaQuery.of(context).size.width < 900;

    return useMobileLayout
        ? const hearing_mobile.HearingAssessmentMobilePage()
        : const HearingAssessmentPage();
  }
}

class _HearingAssessmentPageState extends State<HearingAssessmentPage> {
  late final PtaTestController _ptaController;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  Future<void> _openPdfFromBase64(String b64) async {
    final reportContext = context;
    await openReportPdf(reportContext, b64);
  }

  Future<void> submitReport() async {
    setState(() => isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('http://localhost:8002/hearing/report');

    final left = _ptaController.thresholdsForEar('Left');
    final right = _ptaController.thresholdsForEar('Right');

    final body = {
      'patient_name': 'Test Patient',
      'patient_age': 30,
      'patient_gender': 'Other',

      'wrs_language': 'English',
      'wrs_completed': false,

      'left_ear': {
        'hz_500': left['500'] ?? 0,
        'hz_1000': left['1000'] ?? 0,
        'hz_2000': left['2000'] ?? 0,
        'hz_4000': left['4000'] ?? 0,
      },

      'right_ear': {
        'hz_500': right['500'] ?? 0,
        'hz_1000': right['1000'] ?? 0,
        'hz_2000': right['2000'] ?? 0,
        'hz_4000': right['4000'] ?? 0,
      },

      'wrs_answers': [],
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final pdfB64 = data['pdf_base64'] ?? '';

        if (pdfB64.toString().isNotEmpty) {
          await _openPdfFromBase64(pdfB64);
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('PDF was not returned by backend')),
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Report generation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ptaController = Get.put(PtaTestController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<PtaTestController>(force: true);
    super.dispose();
  }

  Future<void> _stopPtaTest() async {
    await _ptaController.cancel();
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 20.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF103F54),
                                Color(0xFF1E7B82),
                                Color(0xFF38A39E),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0E3A4C,
                                ).withAlpha(((0.18) * 255).round()),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5.w),
                                width: 45.w,
                                height: 45.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF0A4D68),
                                      Color(0xFF1A8C9C),
                                      Color(0xFF34C3B6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.hearing,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hearing Assessment',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Guided PTA plus WRS, redesigned as a compact, modern, medical-style workflow.',
                                      style: TextStyle(
                                        fontSize: 5.sp,
                                        height: 1.3,
                                        color: Colors.white.withAlpha(
                                          ((0.88) * 255).round(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 12.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Ready',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 6.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Obx(() {
                          final step =
                              _ptaController.currentStep ??
                              _ptaController.steps.first;
                          final phase = _ptaController.phase.value;
                          final hasStarted = phase != PtaPhase.idle;
                          final showRunningPanel = hasStarted;

                          final activePanel = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PtaSessionHeader(
                                ear: step.ear,
                                frequency: step.frequency,
                                stepLabel: _ptaController.stepLabel,
                                phaseLabel: _ptaController.phaseLabel,
                                progress: _ptaController.overallProgress,
                              ),
                              SizedBox(height: 28.h),
                              PtaLiveVisualCard(
                                ear: step.ear,
                                frequency: step.frequency,
                                db: _ptaController.currentDb.value,
                                elapsedSeconds:
                                    _ptaController.elapsedSeconds.value,
                                countdownSeconds:
                                    _ptaController.countdownSeconds.value,
                                testing: _ptaController.isTesting,
                                active: _ptaController.isRunning,
                              ),
                            ],
                          );
                          final recap = PtaSessionRecap(
                            latestResult: _ptaController.latestResult.value,
                            busy: _ptaController.isRunning,
                            onRestart: _ptaController.restart,
                          );

                          if (!showRunningPanel) {
                            return Column(
                              children: [
                                PtaIntroCard(
                                  busy: _ptaController.isRunning,
                                  onStart: () =>
                                      _ptaController.startGuidedAssessment(),
                                  completedCount: _ptaController.completedCount,
                                  totalCount: _ptaController.totalSteps,
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              activePanel,
                              SizedBox(height: 28.h),
                              recap,
                            ],
                          );
                        }),
                        SizedBox(height: 12.h),
                        Obx(() {
                          final hasStarted =
                              _ptaController.phase.value != PtaPhase.idle;
                          final ptaCompleted =
                              _ptaController.completedCount >=
                              _ptaController.totalSteps;
                          final showFixedHearButton =
                              hasStarted && !ptaCompleted;
                          return SizedBox(
                            height: showFixedHearButton ? 142.h : 0,
                          );
                        }),

                        SizedBox(width: double.infinity),

                        Obx(() {
                          final ptaCompleted =
                              _ptaController.completedCount >=
                              _ptaController.totalSteps;
                          if (!ptaCompleted) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isLoading ? null : submitReport,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: Text(
                                    'Generate PTA-Only Report',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    backgroundColor: const Color(0xFF134E5E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(
                                      () => const WrsAssessmentResponsivePage(),
                                    );
                                  },
                                  icon: const Icon(Icons.record_voice_over),
                                  label: Text(
                                    'Continue to WRS',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    backgroundColor: const Color(0xFF1E7B82),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Obx(() {
        final hasStarted = _ptaController.phase.value != PtaPhase.idle;
        final ptaCompleted =
            _ptaController.completedCount >= _ptaController.totalSteps;
        final showFixedHearButton = hasStarted && !ptaCompleted;

        if (!showFixedHearButton) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _stopPtaTest,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    'Stop test',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF134E5E),
                    side: const BorderSide(color: Color(0xFF9EC5D1)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              PtaHearButton(
                enabled: _ptaController.isTesting,
                onPressed: () => _ptaController.recordHeard(),
              ),
            ],
          ),
        );
      }),
    );
  }
}
