import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/trainer/trainer_login.dart';
import 'package:frontend/screens/user_landing_page.dart';
import 'participant/workshop_session_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 221, 191, 92),
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        automaticallyImplyLeading: false,
        leading: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/1/10/ICTA_LOGO.gif',
        ),
        title: const Text(
          'Workshop Management System',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.supervised_user_circle_sharp),
            tooltip: 'Landing Page',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserLandingPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'National Workshop Portal',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.home, size: 40),
                children: const [
                  Text(
                    'This portal is designed to facilitate the management of workshops and training sessions.',
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Help'),
                      content: const Text(
                        'Select your role to proceed:\n\n'
                        '- Users can view and register for workshops.\n'
                        '- Trainers can manage their sessions and Feedback Questions.\n'
                        '- Admins can oversee the entire system.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              color: Colors.indigo.shade50,
              child: Column(
                children: [
                  Text(
                    'Welcome to the National Workshop Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04 + 20, // scalable font
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontFamily: 'Roboto',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose your role to continue',
                    style: TextStyle(
                      fontSize: screenWidth * 0.02 + 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Role Cards
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // use Wrap instead of Row for responsiveness
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: getCardWidth(screenWidth),
                        child: RoleCard(
                          title: 'Users',
                          icon: Icons.person,
                          color: Colors.blue,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => WorkshopSessionListScreen(),
                                ),
                              ),
                        ),
                      ),
                      SizedBox(
                        width: getCardWidth(screenWidth),
                        child: RoleCard(
                          title: 'Trainers',
                          icon: Icons.school,
                          color: Colors.green,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const TrainerLoginScreen(),
                                ),
                              ),
                        ),
                      ),
                      SizedBox(
                        width: getCardWidth(screenWidth),
                        child: RoleCard(
                          title: 'Admin',
                          icon: Icons.admin_panel_settings,
                          color: Colors.deepPurple,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminDashboard(),
                                ),
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.grey.shade100,
              width: double.infinity,
              child: Column(
                children: const [
                  Text(
                    '© 2025 National Digital Capacity Building Program',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ICTA Sri Lanka • Contact: info@icta.lk',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getCardWidth(double screenWidth) {
    if (screenWidth > 1200) {
      return screenWidth / 4.5;
    } else if (screenWidth > 800) {
      return screenWidth / 3.5;
    } else {
      return screenWidth / 1.2;
    }
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: color.withValues(alpha: 1),
      hoverColor: color.withValues(alpha: 1),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
