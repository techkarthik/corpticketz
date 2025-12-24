import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/screens/login_screen.dart';
import 'package:corpticketz/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'CorpTicketz',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0056D2), // Corporate Blue
                primary: const Color(0xFF0056D2),
                secondary: const Color(0xFF00D2FF), // Electric Azure
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.transparent,
              cardTheme: CardThemeData(
                color: Colors.white.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              appBarTheme: AppBarThemeData(
                backgroundColor: Colors.white.withOpacity(0.05),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF101520),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            ),
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
