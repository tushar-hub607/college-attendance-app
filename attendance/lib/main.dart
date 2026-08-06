import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const CollegeAttendanceApp());
}

class CollegeAttendanceApp extends StatelessWidget {
  const CollegeAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F2027),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}