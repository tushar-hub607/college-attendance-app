import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true; // Password visibility toggle variable

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    User? user = await ApiService.login(email, password);

    if (mounted) Navigator.pop(context);

    if (user != null) {
      if (mounted) {
        if (user.role == 'student') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentDashboard(user: user)));
        } else if (user.role == 'teacher') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherDashboard(user: user)));
        } else if (user.role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard(user: user)));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Email or Password!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3D Glowing Top Icon
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.cyanAccent.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.05)],
                        ),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.fingerprint_rounded, size: 70, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Smart Attendance',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'College Portal Login',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 35),
                    
                    // 3D Frosted Glass Container Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2),
                          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 30, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.cyanAccent),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field with Hide/Unhide Eye Toggle
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyanAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                              ),
                            ),
                          ),
                          
                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text('Forgot Password?', style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // 3D Elevated Glowing Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent.shade700,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 12,
                                shadowColor: Colors.cyanAccent.withValues(alpha: 0.8),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Register Navigation Link
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(
                        "Don't have an account? Register",
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}