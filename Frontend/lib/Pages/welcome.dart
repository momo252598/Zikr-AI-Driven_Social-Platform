import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(25, 38, 25, 71),
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(54),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '6.30',
                style: GoogleFonts.inriaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 88),
              Text(
                'Welcome,',
                style: GoogleFonts.jua(
                  fontSize: 60,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF000001),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "See What's Next.",
                  style: GoogleFonts.jua(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Image.network(
              //   'https://cdn.builder.io/api/v1/image/assets/11b408c8254a40c882d2b3146606194a/c9c50fdf04b595befdef0f922013a8440bfc09cfe544db2865e0f768ea83f2ad?apiKey=11b408c8254a40c882d2b3146606194a&',
              //   width: double.infinity,
              //   fit: BoxFit.contain,
              // ),
              const SizedBox(height: 36),
              Text(
                'Explore the world of Netflix,\ndive in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 61),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Log in',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000001),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 70, vertical: 20),
                  ),
                  child: Text(
                    'Sign up with email',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF010101),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: SvgPicture.network(
                    'https://cdn.builder.io/api/v1/image/assets/11b408c8254a40c882d2b3146606194a/c28a3bf0a9df9a2d0c5465fbb0bfa0d9b9086472cbaf7278a6ce849fc5161f6c?apiKey=11b408c8254a40c882d2b3146606194a&',
                    width: 34,
                    height: 34,
                  ),
                  label: Text(
                    'Sign up with Google',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000001),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 74, vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
