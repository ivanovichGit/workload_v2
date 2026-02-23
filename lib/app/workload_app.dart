import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/attrition/attrition_page.dart';

class WorkloadApp extends StatelessWidget {
  const WorkloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    final bodyText = GoogleFonts.dmSansTextTheme(base.textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workload Attrition Predictor',
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFF1F2937),
          secondary: const Color(0xFF4B5563),
          surface: const Color(0xFFFFFFFF),
        ),
        textTheme: bodyText.copyWith(
          headlineLarge: GoogleFonts.outfit(
            textStyle: bodyText.headlineLarge,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.outfit(
            textStyle: bodyText.headlineMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          headlineSmall: GoogleFonts.outfit(
            textStyle: bodyText.headlineSmall,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: GoogleFonts.outfit(
            textStyle: bodyText.titleLarge,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.outfit(
            textStyle: bodyText.titleMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF111827), width: 1.2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF111827),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      home: const AttritionPage(),
    );
  }
}
