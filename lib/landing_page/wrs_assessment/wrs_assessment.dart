// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hearing_aid/landing_page/widgets.dart';
import 'package:hearing_aid/others/web_audio.dart';
import 'package:http/http.dart' as http;
import 'package:hearing_aid/others/report_opener_io.dart' if (dart.library.html) 'package:hearing_aid/others/report_opener_web.dart';
import 'package:hearing_aid/pta/pta_controller.dart';

import 'mobile.dart' as wrs_mobile;

class WrsAssessmentPage extends StatefulWidget {
  const WrsAssessmentPage({super.key});

  @override
  State<WrsAssessmentPage> createState() => _WrsAssessmentPageState();
}

class WrsAssessmentResponsivePage extends StatelessWidget {
  const WrsAssessmentResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final useMobileLayout = MediaQuery.of(context).size.width < 900;

    return useMobileLayout ? const wrs_mobile.WrsAssessmentMobilePage() : const WrsAssessmentPage();
  }
}

class _WrsAssessmentPageState extends State<WrsAssessmentPage> {
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String language = 'English';
  bool isLoading = false;

  final Map<String, List<Map<String, dynamic>>> languageBanks = {
    'English': [
      {'id': 1, 'word': 'Apple', 'audio': 'assets/audio/en/Apple.wav'},
      {'id': 2, 'word': 'Water', 'audio': 'assets/audio/en/Water.wav'},
      {'id': 3, 'word': 'School', 'audio': 'assets/audio/en/School.wav'},
      {'id': 4, 'word': 'Garden', 'audio': 'assets/audio/en/Garden.wav'},
      {'id': 5, 'word': 'Window', 'audio': 'assets/audio/en/Window.wav'},
      {'id': 6, 'word': 'Tree', 'audio': 'assets/audio/en/Tree.wav'},
      {'id': 7, 'word': 'Book', 'audio': 'assets/audio/en/Book.wav'},
      {'id': 8, 'word': 'Chair', 'audio': 'assets/audio/en/Chair.wav'},
      {'id': 9, 'word': 'Door', 'audio': 'assets/audio/en/Door.wav'},
      {'id': 10, 'word': 'House', 'audio': 'assets/audio/en/House.wav'},

      {'id': 11, 'word': 'Flower', 'audio': 'assets/audio/en/Flower.wav'},
      {'id': 12, 'word': 'River', 'audio': 'assets/audio/en/River.wav'},
      {'id': 13, 'word': 'Mountain', 'audio': 'assets/audio/en/Mountain.wav'},
      {'id': 14, 'word': 'Computer', 'audio': 'assets/audio/en/Computer.wav'},
      {'id': 15, 'word': 'Phone', 'audio': 'assets/audio/en/Phone.wav'},
      {'id': 16, 'word': 'Bottle', 'audio': 'assets/audio/en/Bottle.wav'},
      {'id': 17, 'word': 'Table', 'audio': 'assets/audio/en/Table.wav'},
      {'id': 18, 'word': 'Pencil', 'audio': 'assets/audio/en/Pencil.wav'},
      {'id': 19, 'word': 'Notebook', 'audio': 'assets/audio/en/Notebook.wav'},
      {'id': 20, 'word': 'Bus', 'audio': 'assets/audio/en/Bus.wav'},

      {'id': 21, 'word': 'Train', 'audio': 'assets/audio/en/Train.wav'},
      {'id': 22, 'word': 'Market', 'audio': 'assets/audio/en/Market.wav'},
      {'id': 23, 'word': 'Hospital', 'audio': 'assets/audio/en/Hospital.wav'},
      {'id': 24, 'word': 'Doctor', 'audio': 'assets/audio/en/Doctor.wav'},
      {'id': 25, 'word': 'Teacher', 'audio': 'assets/audio/en/Teacher.wav'},
    ],

    'Hindi': [
      {'id': 1, 'word': 'सेब', 'audio': 'assets/audio/hi/Apple.wav'},
      {'id': 2, 'word': 'पानी', 'audio': 'assets/audio/hi/Water.wav'},
      {'id': 3, 'word': 'स्कूल', 'audio': 'assets/audio/hi/School.wav'},
      {'id': 4, 'word': 'बगीचा', 'audio': 'assets/audio/hi/Garden.wav'},
      {'id': 5, 'word': 'खिड़की', 'audio': 'assets/audio/hi/Window.wav'},
      {'id': 6, 'word': 'पेड़', 'audio': 'assets/audio/hi/Tree.wav'},
      {'id': 7, 'word': 'किताब', 'audio': 'assets/audio/hi/Book.wav'},
      {'id': 8, 'word': 'कुर्सी', 'audio': 'assets/audio/hi/Chair.wav'},
      {'id': 9, 'word': 'दरवाज़ा', 'audio': 'assets/audio/hi/Door.wav'},
      {'id': 10, 'word': 'घर', 'audio': 'assets/audio/hi/House.wav'},

      {'id': 11, 'word': 'फूल', 'audio': 'assets/audio/hi/Flower.wav'},
      {'id': 12, 'word': 'नदी', 'audio': 'assets/audio/hi/River.wav'},
      {'id': 13, 'word': 'पहाड़', 'audio': 'assets/audio/hi/Mountain.wav'},
      {'id': 14, 'word': 'कंप्यूटर', 'audio': 'assets/audio/hi/Computer.wav'},
      {'id': 15, 'word': 'फोन', 'audio': 'assets/audio/hi/Phone.wav'},
      {'id': 16, 'word': 'बोतल', 'audio': 'assets/audio/hi/Bottle.wav'},
      {'id': 17, 'word': 'मेज', 'audio': 'assets/audio/hi/Table.wav'},
      {'id': 18, 'word': 'पेंसिल', 'audio': 'assets/audio/hi/Pencil.wav'},
      {'id': 19, 'word': 'कॉपी', 'audio': 'assets/audio/hi/Notebook.wav'},
      {'id': 20, 'word': 'बस', 'audio': 'assets/audio/hi/Bus.wav'},

      {'id': 21, 'word': 'ट्रेन', 'audio': 'assets/audio/hi/Train.wav'},
      {'id': 22, 'word': 'बाज़ार', 'audio': 'assets/audio/hi/Market.wav'},
      {'id': 23, 'word': 'अस्पताल', 'audio': 'assets/audio/hi/Hospital.wav'},
      {'id': 24, 'word': 'डॉक्टर', 'audio': 'assets/audio/hi/Doctor.wav'},
      {'id': 25, 'word': 'शिक्षक', 'audio': 'assets/audio/hi/Teacher.wav'},
    ],

    'Kannada': [
      {'id': 1, 'word': 'ಏಪಲ್', 'audio': 'assets/audio/kn/Apple.wav'},
      {'id': 2, 'word': 'ನೀರು', 'audio': 'assets/audio/kn/Water.wav'},
      {'id': 3, 'word': 'ಶಾಲೆ', 'audio': 'assets/audio/kn/School.wav'},
      {'id': 4, 'word': 'ತೋಟ', 'audio': 'assets/audio/kn/Garden.wav'},
      {'id': 5, 'word': 'ಕಿಟಕಿ', 'audio': 'assets/audio/kn/Window.wav'},
      {'id': 6, 'word': 'ಮರ', 'audio': 'assets/audio/kn/Tree.wav'},
      {'id': 7, 'word': 'ಪುಸ್ತಕ', 'audio': 'assets/audio/kn/Book.wav'},
      {'id': 8, 'word': 'ಕುರ್ಚಿ', 'audio': 'assets/audio/kn/Chair.wav'},
      {'id': 9, 'word': 'ಬಾಗಿಲು', 'audio': 'assets/audio/kn/Door.wav'},
      {'id': 10, 'word': 'ಮನೆ', 'audio': 'assets/audio/kn/House.wav'},

      {'id': 11, 'word': 'ಹೂವು', 'audio': 'assets/audio/kn/Flower.wav'},
      {'id': 12, 'word': 'ನದಿ', 'audio': 'assets/audio/kn/River.wav'},
      {'id': 13, 'word': 'ಬೆಟ್ಟ', 'audio': 'assets/audio/kn/Mountain.wav'},
      {'id': 14, 'word': 'ಕಂಪ್ಯೂಟರ್', 'audio': 'assets/audio/kn/Computer.wav'},
      {'id': 15, 'word': 'ದೂರವಾಣಿ', 'audio': 'assets/audio/kn/Phone.wav'},
      {'id': 16, 'word': 'ಬಾಟಲಿ', 'audio': 'assets/audio/kn/Bottle.wav'},
      {'id': 17, 'word': 'ಮೇಜು', 'audio': 'assets/audio/kn/Table.wav'},
      {'id': 18, 'word': 'ಪೆನ್ಸಿಲ್', 'audio': 'assets/audio/kn/Pencil.wav'},
      {'id': 19, 'word': 'ನೋಟ್‌ಬುಕ್', 'audio': 'assets/audio/kn/Notebook.wav'},
      {'id': 20, 'word': 'ಬಸ್', 'audio': 'assets/audio/kn/Bus.wav'},
      {'id': 21, 'word': 'ರೈಲು', 'audio': 'assets/audio/kn/Train.wav'},
      {'id': 22, 'word': 'ಮಾರುಕಟ್ಟೆ', 'audio': 'assets/audio/kn/Market.wav'},
      {'id': 23, 'word': 'ಆಸ್ಪತ್ರೆ', 'audio': 'assets/audio/kn/Hospital.wav'},
      {'id': 24, 'word': 'ವೈದ್ಯ', 'audio': 'assets/audio/kn/Doctor.wav'},
      {'id': 25, 'word': 'ಶಿಕ್ಷಕ', 'audio': 'assets/audio/kn/Teacher.wav'},
    ],

    'Telugu': [
      {'id': 1, 'word': 'ఆపిల్', 'audio': 'assets/audio/te/Apple.wav'},
      {'id': 2, 'word': 'నీరు', 'audio': 'assets/audio/te/Water.wav'},
      {'id': 3, 'word': 'పాఠశాల', 'audio': 'assets/audio/te/School.wav'},
      {'id': 4, 'word': 'తోట', 'audio': 'assets/audio/te/Garden.wav'},
      {'id': 5, 'word': 'కిటికీ', 'audio': 'assets/audio/te/Window.wav'},
      {'id': 6, 'word': 'చెట్టు', 'audio': 'assets/audio/te/Tree.wav'},
      {'id': 7, 'word': 'పుస్తకం', 'audio': 'assets/audio/te/Book.wav'},
      {'id': 8, 'word': 'కుర్చీ', 'audio': 'assets/audio/te/Chair.wav'},
      {'id': 9, 'word': 'తలుపు', 'audio': 'assets/audio/te/Door.wav'},
      {'id': 10, 'word': 'ఇల్లు', 'audio': 'assets/audio/te/House.wav'},

      {'id': 11, 'word': 'పువ్వు', 'audio': 'assets/audio/te/Flower.wav'},
      {'id': 12, 'word': 'నది', 'audio': 'assets/audio/te/River.wav'},
      {'id': 13, 'word': 'కొండ', 'audio': 'assets/audio/te/Mountain.wav'},
      {'id': 14, 'word': 'కంప్యూటర్', 'audio': 'assets/audio/te/Computer.wav'},
      {'id': 15, 'word': 'ఫోన్', 'audio': 'assets/audio/te/Phone.wav'},
      {'id': 16, 'word': 'సీసా', 'audio': 'assets/audio/te/Bottle.wav'},
      {'id': 17, 'word': 'బల్ల', 'audio': 'assets/audio/te/Table.wav'},
      {'id': 18, 'word': 'పెన్సిల్', 'audio': 'assets/audio/te/Pencil.wav'},
      {'id': 19, 'word': 'నోట్‌బుక్', 'audio': 'assets/audio/te/Notebook.wav'},
      {'id': 20, 'word': 'బస్సు', 'audio': 'assets/audio/te/Bus.wav'},

      {'id': 21, 'word': 'రైలు', 'audio': 'assets/audio/te/Train.wav'},
      {'id': 22, 'word': 'మార్కెట్', 'audio': 'assets/audio/te/Market.wav'},
      {'id': 23, 'word': 'ఆసుపత్రి', 'audio': 'assets/audio/te/Hospital.wav'},
      {'id': 24, 'word': 'డాక్టర్', 'audio': 'assets/audio/te/Doctor.wav'},
      {'id': 25, 'word': 'ఉపాధ్యాయుడు', 'audio': 'assets/audio/te/Teacher.wav'},
    ],
  };

  List<Map<String, dynamic>> wordBank = [];
  List<Map<String, dynamic>> wrsSession = [];
  final Map<int, String?> wrsAnswers = {};

  bool get wrsCompleted {
    if (wordBank.isEmpty) return false;
    return wordBank.every((word) => (wrsAnswers[word['id']] ?? '').toString().isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    // _ptaController = Get.put(PtaTestController());
    prepareWrsSession();
  }

  @override
  void dispose() {
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  void prepareWrsSession() {
    final bank = languageBanks[language] ?? languageBanks['English']!;
    final pool = List<Map<String, dynamic>>.from(bank);
    pool.shuffle(_random);
    wrsSession = pool.take(5).toList();
    wordBank = wrsSession.map((word) => {'id': word['id'], 'word': word['word'], 'audio': word['audio'], 'options': _buildOptions(word['word'])}).toList();
    wrsAnswers.clear();
  }

  List<String> _buildOptions(String correct) {
    final options = <String>[correct];
    final bank = languageBanks[language] ?? languageBanks['English']!;
    final others = bank.map((entry) => entry['word'] as String).where((word) => word != correct).toList();
    others.shuffle(_random);
    options.addAll(others.take(3));
    options.shuffle(_random);
    return options;
  }

  Future<void> playWordAudio(int wordId, {double pan = 0.0}) async {
    try {
      final bank = languageBanks[language] ?? languageBanks['English']!;
      final item = bank.firstWhere((word) => word['id'] == wordId, orElse: () => <String, dynamic>{});
      final String? assetPath = item['audio'] as String?;
      if (assetPath == null || assetPath.isEmpty) {
        return;
      }
      // On web, try the corresponding .wav first if the asset is .mp3 and
      // fall back to the original asset if that fails. This helps avoid
      // small/invalid mp3 placeholders that exist in the repo.
      if (kIsWeb) {
        final lower = assetPath.toLowerCase();
        final isMp3 = lower.endsWith('.mp3');
        if (isMp3) {
          final wav = assetPath.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '.wav');
          final ok = await playWebAudio(wav, pan: pan);
          if (ok) return;
        }
        // try original asset (may be mp3 or wav)
        final fallbackOk = await playWebAudio(assetPath, pan: pan);
        if (fallbackOk) return;
        // On web do not fall back to native audioplayers; it can throw noisy platform exceptions.
        return;
      }

      await _audioPlayer.stop();
      final relativePath = assetPath.replaceFirst('assets/', '');
      try {
        await _audioPlayer.play(AssetSource(relativePath));
      } catch (_) {
        final base = relativePath.replaceAll(RegExp(r'\.(mp3|wav)', caseSensitive: false), '');
        final tryWav = '$base.wav';
        final tryMp3 = '$base.mp3';
        if (!relativePath.endsWith('.wav')) {
          try {
            await _audioPlayer.play(AssetSource(tryWav));
            return;
          } catch (_) {}
        }
        if (!relativePath.endsWith('.mp3')) {
          try {
            await _audioPlayer.play(AssetSource(tryMp3));
            return;
          } catch (_) {}
        }
      }
    } catch (_) {
      // Intentionally quiet: WRS playback should not block the report flow.
    }
  }

  Future<void> submitReport(bool mounted, BuildContext context) async {
    setState(() => isLoading = true);
    final uri = Uri.parse('http://localhost:8002/hearing/report');
    final ptaController = Get.isRegistered<PtaTestController>() ? Get.find<PtaTestController>() : null;
    final left = ptaController?.thresholdsForEar('Left') ?? {'500': 0.0, '1000': 0.0, '2000': 0.0, '4000': 0.0};
    final right = ptaController?.thresholdsForEar('Right') ?? {'500': 0.0, '1000': 0.0, '2000': 0.0, '4000': 0.0};
    final body = {
      'patient_name': 'Test Patient',
      'patient_age': 30,
      'patient_gender': 'Other',
      'wrs_language': language,
      'wrs_completed': true,
      'left_ear': {'hz_500': left['500'] ?? 0.0, 'hz_1000': left['1000'] ?? 0.0, 'hz_2000': left['2000'] ?? 0.0, 'hz_4000': left['4000'] ?? 0.0},
      'right_ear': {'hz_500': right['500'] ?? 0.0, 'hz_1000': right['1000'] ?? 0.0, 'hz_2000': right['2000'] ?? 0.0, 'hz_4000': right['4000'] ?? 0.0},
      'wrs_answers': wordBank
          .map(
            (word) => {
              'word_id': word['id'],
              'prompt_word': word['word'],
              'selected_word': (wrsAnswers[word['id']] ?? '').toString(),
              'correct_word': word['word'],
              'is_correct': (wrsAnswers[word['id']] ?? '') == word['word'],
            },
          )
          .toList(),
    };

    try {
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 25));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pdfB64 = (data['pdf_base64'] ?? '').toString();

        if (pdfB64.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated, but PDF output is empty. Check backend wkhtmltopdf setup.')));
          return;
        }

        await _openPdfFromBase64(pdfB64, context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generation timed out. Please verify backend is running on port 8002.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to generate report: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _openPdfFromBase64(String b64, BuildContext context) async {
    await openReportPdf(context, b64);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Word Recognition Test'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LandingWrsSection(
              isWide: isWide,
              language: language,
              wordBank: wordBank,
              wrsAnswers: wrsAnswers,
              onLanguageChanged: (value) {
                setState(() {
                  language = value;
                  prepareWrsSession();
                });
              },
              onPlayWord: (id) => playWordAudio(id),
              onWordSelected: (id, option) {
                setState(() {
                  wrsAnswers[id] = option;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading || !wrsCompleted ? null : () => submitReport(mounted, context),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  isLoading ? 'Generating Report...' : 'Generate PTA + WRS Report',
                  style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: const Color(0xFF134E5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            if (!wrsCompleted)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  'Complete all ${wordBank.length} words before generating the PTA + WRS report.',
                  style: TextStyle(fontSize: 8.sp, color: const Color(0xFF475569), height: 1.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
