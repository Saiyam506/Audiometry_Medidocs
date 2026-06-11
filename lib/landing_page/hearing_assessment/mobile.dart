import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hearing_aid/landing_page/wrs_assessment/wrs_assessment.dart';

import '../../pta/pta_controller.dart';
import '../../pta/pta_models.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hearing_aid/others/report_opener_io.dart'
    if (dart.library.html) 'package:hearing_aid/others/report_opener_web.dart';

class HearingAssessmentMobilePage extends StatefulWidget {
  const HearingAssessmentMobilePage({super.key});

  @override
  State<HearingAssessmentMobilePage> createState() =>
      _HearingAssessmentMobilePageState();
}

class _HearingAssessmentMobilePageState
    extends State<HearingAssessmentMobilePage> {
  late final PtaTestController _ptaController;
  bool isLoading = false;

  int _overallScoreForEar(String ear) {
    final earResults = _ptaController.results
        .where((result) => result.ear.toLowerCase() == ear.toLowerCase())
        .toList();
    if (earResults.isEmpty) {
      return 0;
    }
    final total = earResults.fold<int>(0, (sum, result) => sum + result.score);
    return (total / earResults.length).round();
  }

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
    Get.delete<PtaTestController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Obx(() {
                          final ptaCompleted =
                              _ptaController.completedCount >=
                              _ptaController.totalSteps;

                          if (ptaCompleted) {
                            final leftScore = _overallScoreForEar('Left');
                            final rightScore = _overallScoreForEar('Right');

                            return Container(
                              margin: EdgeInsets.only(top: 18.h),
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                    size: 64.sp,
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "Assessment Complete",
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "Your PTA assessment has been completed successfully.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PtaOverallScoreCard(
                                          label: "Left PTA Score",
                                          score: leftScore,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _PtaOverallScoreCard(
                                          label: "Right PTA Score",
                                          score: rightScore,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48.h,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Get.to(
                                          () =>
                                              const WrsAssessmentResponsivePage(),
                                        );
                                      },
                                      icon: const Icon(Icons.record_voice_over),
                                      label: const Text("Continue to WRS"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1565FF,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48.h,
                                    child: OutlinedButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : submitReport,
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text("Generate PTA Report"),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44.h,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        _ptaController.restart();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Take Test Again"),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (_ptaController.phase.value == PtaPhase.idle) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Center(
                                  child: Image.asset(
                                    'assets/company/logo_with_text.png',
                                    width: 124.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                IntroScreen(controller: _ptaController),
                              ],
                            );
                          }

                          return TestingScreen(controller: _ptaController);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}

class _PtaOverallScoreCard extends StatelessWidget {
  final String label;
  final int score;

  const _PtaOverallScoreCard({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8FF)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "$score",
            style: TextStyle(
              fontSize: 20.sp,
              color: const Color(0xFF1565FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningRing extends StatelessWidget {
  final double size;
  final Color color;

  const _ListeningRing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class TestingScreen extends StatefulWidget {
  final PtaTestController controller;

  const TestingScreen({super.key, required this.controller});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final step = controller.currentStep ?? controller.steps.first;

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(height: 12.h),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hearing, color: Color(0xFF2F6BFF)),
              SizedBox(width: 8.w),
              Text(
                "${step.ear.toUpperCase()} EAR",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2F6BFF),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 18.h),

        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = _pulseController.value;
            final outerScale = 0.92 + (pulse * 0.16);
            final middleScale = 0.94 + ((1 - pulse) * 0.08);
            final iconLift = (pulse < 0.5 ? pulse : 1 - pulse) * 8.h;

            return SizedBox(
              width: 158.w,
              height: 158.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: outerScale,
                    child: Opacity(
                      opacity: 0.25 + ((1 - pulse) * 0.45),
                      child: _ListeningRing(
                        size: 150.w,
                        color: Colors.blue.shade100,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: middleScale,
                    child: Opacity(
                      opacity: 0.45 + (pulse * 0.28),
                      child: _ListeningRing(
                        size: 120.w,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ),
                  _ListeningRing(size: 92.w, color: Colors.blue.shade200),
                  Container(
                    width: 68.w,
                    height: 68.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1565FF,
                          ).withValues(alpha: 0.16 + (pulse * 0.08)),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -iconLift),
                    child: Icon(
                      Icons.hearing,
                      size: 44.sp,
                      color: const Color(0xFF2F6BFF),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        SizedBox(height: 16.h),

        Text(
          "Listening...",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 12.h),

        Text(
          "You will hear a tone.\nTap the button when you hear it.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
        ),

        SizedBox(height: 18.h),

        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: () {
              if (controller.isTesting) {
                controller.recordHeard();
              }
            },
            icon: const Icon(Icons.hearing),
            label: Text(
              "I HEAR IT",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),

        SizedBox(height: 10.h),

        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton.icon(
            onPressed: () => controller.cancel(),
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(
              "STOP TEST",
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565FF),
              side: const BorderSide(color: Color(0xFFB7CBFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),

        SizedBox(height: 14.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${controller.completedCount} of ${controller.totalSteps}",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565FF),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: controller.overallProgress,
                  minHeight: 8.h,
                  backgroundColor: const Color(0xFFE9EDF5),
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                "Keep going, you're doing great!",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class IntroScreen extends StatelessWidget {
  final PtaTestController controller;

  const IntroScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 2.h),

        Icon(Icons.hearing, size: 40.sp, color: const Color(0xFF1565FF)),

        SizedBox(height: 4.h),

        Text(
          "Audiometry Test",
          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 4.h),

        Text(
          "Hearing check made simple",
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),

        SizedBox(height: 7.h),

        Container(
          width: 106.w,
          height: 106.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.headphones,
            size: 56.sp,
            color: const Color(0xFF1565FF),
          ),
        ),

        SizedBox(height: 7.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6ECF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Before you start",
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 6.h),

              _instructionRow(Icons.volume_off, "Sit in a quiet place"),

              SizedBox(height: 5.h),

              _instructionRow(
                Icons.headphones,
                "Wear your headphones properly",
              ),

              SizedBox(height: 5.h),

              _instructionRow(Icons.touch_app, "Tap only when you hear a tone"),

              SizedBox(height: 5.h),

              _instructionRow(Icons.graphic_eq, "Some tones may be very soft"),

              SizedBox(height: 5.h),

              _instructionRow(
                Icons.remove_red_eye,
                "Stay focused throughout the test",
              ),
            ],
          ),
        ),

        SizedBox(height: 7.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 20.sp,
                color: const Color(0xFF1565FF),
              ),

              SizedBox(width: 8.w),

              Flexible(
                child: Text(
                  "Estimated Duration  •  2 - 3 Minutes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 7.h),

        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton.icon(
            onPressed: () {
              controller.startGuidedAssessment();
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(
              "START TEST",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),

        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _instructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565FF), size: 21.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }
}
