import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  final User user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _otpController = TextEditingController();
  String _monthlyPercentage = '0.0';
  String _yearlyPercentage = '0.0';
  int _presentDays = 0;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final data = await ApiService.getReports(widget.user.id, widget.user.role);
    if (data != null && mounted) {
      setState(() {
        _monthlyPercentage = data['monthlyPercentage']?.toString() ?? '0.0';
        _yearlyPercentage = data['yearlyPercentage']?.toString() ?? '0.0';
        _presentDays = data['presentDays'] ?? 0;
        _history = data['history'] ?? [];
      });
    }
  }

  void _submitAttendance() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid 4-digit OTP')));
      return;
    }

    bool success = await ApiService.markStudentAttendance(widget.user.id, widget.user.name, otp);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Attendance Marked Successfully!' : 'Invalid/Expired OTP or Already Marked!')),
      );
      if (success) {
        _otpController.clear();
        _loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student: ${widget.user.name}'),
        backgroundColor: const Color(0xFF203A43),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Stats Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Present Days', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$_presentDays', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.white24),
                  Column(
                    children: [
                      const Text('Month %', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$_monthlyPercentage%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.white24),
                  Column(
                    children: [
                      const Text('Year %', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$_yearlyPercentage%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Enter Teacher OTP to Mark Attendance', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                child: const Text('Submit Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('My Attendance History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No attendance history found', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        
                        // Intl formatting for date (e.g., 2026-08-06 -> 06 Aug 2026)
                        String formattedDate = item['date'];
                        try {
                          DateTime parsedDate = DateTime.parse(item['date']);
                          formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
                        } catch (_) {}

                        return Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: ListTile(
                            title: Text('Date: $formattedDate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Text('Present', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}