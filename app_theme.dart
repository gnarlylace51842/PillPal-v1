import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color white = Colors.white;

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF42A5F5), Colors.white],
    stops: [0.0, 0.3],
  );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: deepBlue,
        primary: deepBlue,
        secondary: lightBlue,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: deepBlue),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightBlue.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: deepBlue, width: 2),
        ),
        filled: true,
        fillColor: white,
      ),

      iconTheme: const IconThemeData(color: deepBlue),
    );
  }
}

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: body,
      ),
    );
  }
}
