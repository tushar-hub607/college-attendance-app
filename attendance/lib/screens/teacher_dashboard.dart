import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final User user;
  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _generatedOtp;
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

  void _startSession() async {
    String? otp = await ApiService.startTeacherSession(widget.user.id, widget.user.name);
    if (otp != null && mounted) {
      setState(() => _generatedOtp = otp);
      _loadStats();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session Started! Attendance Marked & OTP Generated.')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start session')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher: ${widget.user.name}'),
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
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Attendance Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_generatedOtp != null) ...[
              const Text('Active Session OTP (Valid for 1 min):', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 5),
              Text(
                _generatedOtp!,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 6),
              ),
              const SizedBox(height: 20),
            ],
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
                        
                        // Intl formatting for teacher date history
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