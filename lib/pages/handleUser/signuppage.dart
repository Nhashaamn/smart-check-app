import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_check/components/textfeild.dart';
import 'package:smart_check/pages/handleUser/login_Page.dart';
import 'package:smart_check/wrapper.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  bool isloading = false;
  FocusNode nameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (passwordController.text != confirmpasswordController.text) {
      Get.snackbar("Error", "Passwords do not match",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
      return;
    }
    if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
      Get.snackbar("Error", "Name, email, and password cannot be empty",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
      return;
    }

    setState(() => isloading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      });

      Get.offAll(const Wrapper());
      Get.snackbar("Success", "User created successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
    } finally {
      setState(() => isloading = false);
    }
  }

  Widget _buildButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: const Color(0xFF419C9C),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth > 600 ? 400 : double.infinity;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/signup.json',
                            width: maxWidth * 0.8,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person_add,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Create Account',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextFieldCustom(
                              Controller: nameController,
                              focusNode: nameFocusNode,
                              hintText: "Name",
                              prefixIcon: Icons.person,
                              hintStyle: const TextStyle(color: Colors.white70),
                              textStyle: const TextStyle(color: Colors.white),
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(emailFocusNode);
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextFieldCustom(
                              Controller: emailController,
                              focusNode: emailFocusNode,
                              hintText: "Email",
                              prefixIcon: Icons.email,
                              hintStyle: const TextStyle(color: Colors.white70),
                              textStyle: const TextStyle(color: Colors.white),
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(passwordFocusNode);
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextFieldCustom(
                              Controller: passwordController,
                              focusNode: passwordFocusNode,
                              hintText: "Password",
                              obscureText: true,
                              prefixIcon: Icons.lock,
                              hintStyle: const TextStyle(color: Colors.white70),
                              textStyle: const TextStyle(color: Colors.white),
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(confirmPasswordFocusNode);
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextFieldCustom(
                              Controller: confirmpasswordController,
                              focusNode: confirmPasswordFocusNode,
                              hintText: "Confirm Password",
                              obscureText: true,
                              prefixIcon: Icons.lock,
                              hintStyle: const TextStyle(color: Colors.white70),
                              textStyle: const TextStyle(color: Colors.white),
                              onSubmitted: (_) => signup(),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildButton(
                            text: "Sign Up",
                            isLoading: isloading,
                            onPressed: signup,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: GoogleFonts.roboto(
                                  color: Colors.white70,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Get.to(const LoginPage()),
                                child: Text(
                                  "Log In",
                                  style: GoogleFonts.roboto(
                                    color: const Color(0xFFE0E7FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
  }
}