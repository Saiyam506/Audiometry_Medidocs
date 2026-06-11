import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'landing_page/hearing_assessment/hearing_assessment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hearing Aid',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E7B82), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF4FAFF),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: Color(0xFF16324F), elevation: 0, centerTitle: true),
          textTheme: Typography.blackCupertino,
        ),
        home: const HearingAssessmentResponsivePage(),
      ),
    );
  }
}
