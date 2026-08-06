import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _reportData = {};
  List<dynamic> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  void _fetchAdminData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getReports(widget.user.id, widget.user.role);
    final users = await ApiService.getAllUsers();
    
    if (data != null && mounted) {
      setState(() {
        _reportData = data;
        _allUsers = users;
        _isLoading = false;
      });
    }
  }

  // Popup dialog to show student/teacher list on card click
  void _showUserListDialog(String roleType) {
    final filteredUsers = _allUsers.where((u) => u['role'] == roleType).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3C72),
          title: Text(
            'Total ${roleType.toUpperCase()}S (${filteredUsers.length})',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users found', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      return Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleType == 'student' ? Colors.cyanAccent : Colors.orangeAccent,
                            child: Text(u['name'][0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(u['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(u['email'] ?? 'No Email', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  void _downloadPDF(List reports) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('College Attendance Master Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateTime.now().toIso8601String().split('T')[0]}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['User Name', 'Role', 'Status', 'Date'],
                data: reports.map((item) => [
                  item['userName'] ?? '',
                  item['role'] ?? '',
                  item['status'] ?? 'Present',
                  item['date'] ?? '',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'attendance_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reportData['allAttendance'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Portal: ${widget.user.name}'),
        backgroundColor: const Color(0xFF203A43),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.cyanAccent),
            onPressed: () => _downloadPDF(reports),
            tooltip: 'Export to PDF',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAdminData),
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
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showUserListDialog('student'),
                          child: _buildStatCard('Total Students', '${_reportData['totalStudents'] ?? 0}', Colors.blueAccent),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showUserListDialog('teacher'),
                          child: _buildStatCard('Total Teachers', '${_reportData['totalTeachers'] ?? 0}', Colors.orangeAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Present Students Today', '${_reportData['todayPresentStudents'] ?? 0}', Colors.greenAccent)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard('Present Teachers Today', '${_reportData['todayPresentTeachers'] ?? 0}', Colors.purpleAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attendance History Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ElevatedButton.icon(
                        onPressed: () => _downloadPDF(reports),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: reports.isEmpty
                        ? const Center(child: Text('No records found', style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final item = reports[index];
                              return Card(
                                color: Colors.white.withValues(alpha: 0.1),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: item['role'] == 'teacher' ? Colors.orangeAccent : Colors.cyanAccent,
                                    child: Icon(item['role'] == 'teacher' ? Icons.school : Icons.person, color: Colors.black),
                                  ),
                                  title: Text(item['userName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text('Role: ${(item['role'] ?? '').toUpperCase()} | Date: ${item['date'] ?? ''}', style: const TextStyle(color: Colors.white70)),
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

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}