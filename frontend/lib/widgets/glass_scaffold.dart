import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const GlassScaffold({
    super.key,
    this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0F172A), // Deep Slate/Blue fallback
          ),
        ),
        if (kIsWeb || !Platform.isWindows) 
           const SizedBox.shrink()
        else
          Positioned.fill(
            child: Image.file(
              File(r'C:\Users\Karthik\.gemini\antigravity\brain\ab992339-53e0-4319-a959-ccafe747e76a\windows_professional_background_1766323268996.png'),
              fit: BoxFit.cover,
            ),
          ),
        // Gradient Overlay for Depth
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        // Glassmorphism Overlay (Global)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        // Actual Scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          drawer: drawer,
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ],
    );
  }
}
