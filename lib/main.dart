import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';

const black = Color(0xFF111111);
const grey = Color(0xFF888888);
const background = Color(0xFFFFFFFF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const BlvkApp());
}

class BlvkApp extends StatelessWidget {
  const BlvkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLVK Clothing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: black,
          surface: background,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
        // Black top bar, like the reference design.
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Arial',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        // Black buttons with square-ish corners.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: black,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        dividerTheme: const DividerThemeData(color: Colors.black12),
      ),
      home: const HomeScreen(),
    );
  }
}