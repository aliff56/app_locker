import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const SplashScreen({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Centered icon & title
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon (neumorphic style subtle shadow)
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icon/app_icon.png', // ensure path in pubspec
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'App Lock',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // "Get Started" button at bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onContinue,
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
