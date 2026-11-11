import 'dart:async';
import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:expenses_tracker/Auth/login_screen.dart';
import 'package:expenses_tracker/Screens/dashboard_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardShell()),

      );
    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,

              colors: [
                Color(0xFF2E0854),
                Color(0xFF180B30),
                Color(0xFF0C1033),

              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 150,
                  left: 50,

                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(

                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 3),
                          blurRadius: 5,
                        color: Colors.white70,
                        spreadRadius: 5,

                        )
                      ]
                    ),
                  ),
              ),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: EdgeInsets.symmetric(vertical: 40,  horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        )
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                           ShaderMask(
                             shaderCallback: (bounds) => LinearGradient(
                                 colors: [Colors.cyan, Colors.deepPurple]
                             ).createShader(bounds),
                             child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 100,
                              color: Colors.white,
                             ),
                           ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                TyperAnimatedText(
                                  'Expenses Tracker ',
                                  speed: Duration(milliseconds: 200),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.cyanAccent.withValues(alpha: 0.5),
                                        offset: Offset(7, 10)
                                      )
                                    ]
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                             child: Text(
                              'Manage Your daily Expenses Easily',
                              style:  GoogleFonts.poppins(
                                fontSize: 12,
                                letterSpacing: 0.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,

                              )),
                           ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
