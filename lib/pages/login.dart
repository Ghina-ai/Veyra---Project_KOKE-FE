import 'package:fe/main.dart';
import 'package:fe/pages/HomePage.dart';
import 'package:fe/pages/register.dart';
import 'package:fe/services/api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ant_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool togglePass = true;
  bool rememberMe = false;

  final Color coral = const Color(0xFFE98568);
  final Color muted = const Color(0xFF858585);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // STYLE INPUT
  InputDecoration inputStyle(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        fontSize: 11,
        color: const Color(0xFF929292),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: coral, width: 1),
      ),
    );
  }

  // LABEL INPUT
  Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  // TOMBOL SOSIAL
  Widget socialButton({required Widget icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Center(child: icon),
      ),
    );
  }

  //FUNGSI LOGIN
  Future<void> login() async {
    try {
      final response = await ApiServices.post('/auth/login', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      final token = response['data']['token'];

      await ApiServices.saveToken(token);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER CORAL
              Container(
                height: 225,
                decoration: BoxDecoration(
                  color: coral,
                  borderRadius: BorderRadius.zero,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      left: -48,
                      top: 25,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8D58B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -42,
                      bottom: -38,
                      child: Container(
                        width: 125,
                        height: 125,
                        decoration: const BoxDecoration(
                          color: Color(0xFF82D8B4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please enter your details to sign in.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // CARD LOGIN
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // EMAIL
                      buildLabel('Email'),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.dmSans(fontSize: 12),
                          decoration: inputStyle(
                            'Enter your email',
                            prefix: Icon(
                              Icons.email_outlined,
                              color: muted,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD
                      buildLabel('Password'),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: passwordController,
                          obscureText: togglePass,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => login(),
                          style: GoogleFonts.dmSans(fontSize: 12),
                          decoration: inputStyle(
                            'Enter your password',
                            prefix: Icon(
                              Icons.lock_outline,
                              color: muted,
                              size: 18,
                            ),
                            suffix: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  togglePass = !togglePass;
                                });
                              },
                              icon: Icon(
                                togglePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: muted,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // REMEMBER ME DAN FORGOT PASSWORD
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 22,
                            child: Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.black,
                              side: const BorderSide(color: Color(0xFFBDBDBD)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Remember me',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: muted,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 17),

                      // LOGIN BUTTON
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Log in',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // PEMISAH OR
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE7E7E7)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE7E7E7)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SOCIAL ICONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          socialButton(
                            icon: const Iconify(
                              AntDesign.google_outlined,
                              size: 20,
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 15),
                          socialButton(
                            icon: const Iconify(
                              AntDesign.apple_filled,
                              size: 23,
                              color: Color(0xFF424242),
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 15),
                          socialButton(
                            icon: const Iconify(
                              AntDesign.facebook_filled,
                              size: 21,
                              color: Color(0xFF1877F2),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // LINK REGISTER
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
