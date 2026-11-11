import 'package:fe/main.dart';
import 'package:fe/pages/login.dart';
import 'package:fe/services/api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ant_design.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  bool togglePass = true;
  bool rememberMe = false;
  bool loading = false;

  final Color coral = const Color(0xFFE98568);
  final Color muted = const Color(0xFF858585);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  InputDecoration inputStyle(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        fontSize: 12,
        color: const Color(0xFF929292),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixIconConstraints: const BoxConstraints(minWidth: 45, minHeight: 44),
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: coral, width: 1.2),
      ),
    );
  }

  Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget socialButton({required Widget icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 48,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Center(child: icon),
      ),
    );
  }

  //FUNGSI REGIS
  Future<void> register() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi')));
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiServices.post('/auth/register', {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),

        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER CORAL
              Container(
                height: 185,
                decoration: BoxDecoration(color: coral),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // CIRCLE KUNING
                    Positioned(
                      left: -60,
                      top: 20,
                      child: Container(
                        width: 135,
                        height: 135,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8D58B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // CIRCLE HIJAU
                    Positioned(
                      right: -48,
                      bottom: -45,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Color(0xFF82D8B4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // HEADER TEXT
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please register to get started.',
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

              // REGISTER CARD
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 29, 24, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // USERNAME
                      buildLabel('Username'),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.dmSans(fontSize: 10),
                          decoration: inputStyle(
                            'Enter your username',
                            prefix: Icon(
                              Icons.person_outline,
                              color: muted,
                              size: 19,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // MOBILE NUMBER
                      buildLabel('Email'),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.dmSans(fontSize: 10),
                          decoration: inputStyle(
                            'Enter your Email',
                            prefix: Icon(
                              Icons.email_outlined,
                              color: muted,
                              size: 19,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      buildLabel('Password'),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: passwordController,
                          obscureText: togglePass,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.dmSans(fontSize: 10),
                          decoration: inputStyle(
                            'Create your password',
                            prefix: Icon(
                              Icons.lock_outline,
                              color: muted,
                              size: 19,
                            ),
                            suffix: IconButton(
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
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // REMEMBER ME
                      Row(
                        children: [
                          SizedBox(
                            width: 22,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Remember me',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: muted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // CREATE ACCOUNT BUTTON
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: loading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Create Account',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // OR DIVIDER
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

                      const SizedBox(height: 17),

                      // SOCIAL ICONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          socialButton(
                            icon: const Iconify(
                              AntDesign.google_outlined,
                              size: 22,
                              color: Color(0xFF4285F4),
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 16),
                          socialButton(
                            icon: const Iconify(
                              AntDesign.apple_filled,
                              size: 24,
                              color: Color(0xFF424242),
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 16),
                          socialButton(
                            icon: const Iconify(
                              AntDesign.facebook_filled,
                              size: 23,
                              color: Color(0xFF1877F2),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 19),

                      // LINK TO LOGIN
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
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
