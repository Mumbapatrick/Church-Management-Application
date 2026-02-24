import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'model/user.dart';
import 'membershiprequests.dart';
import 'donation.dart';
import 'events.dart';
import 'devotion.dart';
import 'prayer_request.dart';
import 'meetingscheduler.dart';
import 'authscreen.dart';
import 'admindashboard.dart';

class Dashboard extends StatelessWidget {
  final User user;
  final Function(String screen)? onNavigate;
  final VoidCallback? onLogout;

  const Dashboard({
    Key? key,
    required this.user,
    this.onNavigate,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Membership Requests",
        "icon": LucideIcons.userPlus,
        "color": [Colors.blue, Colors.blueAccent],
        "screen": "membership_request",
        "description": "Request to become a member",
      },
      {
        "title": "Events",
        "icon": LucideIcons.calendarDays,
        "color": [Colors.indigo, Colors.indigoAccent],
        "screen": "events",
        "description": "View upcoming church events",
      },
      {
        "title": "Donations",
        "icon": LucideIcons.dollarSign,
        "color": [Colors.green, Colors.greenAccent],
        "screen": "donations",
        "description": "Make tithes and offerings",
      },
      {
        "title": "Messages",
        "icon": LucideIcons.messageSquare,
        "color": [Colors.orange, Colors.deepOrange],
        "screen": "messages",
        "description": "Devotionals and announcements",
      },
      {
        "title": "Prayer Requests",
        "icon": LucideIcons.heart,
        "color": [Colors.pink, Colors.pinkAccent],
        "screen": "prayer_requests",
        "description": "Submit and view prayer requests",
      },
      {
        "title": "Meet with Pastor",
        "icon": LucideIcons.clock,
        "color": [Colors.teal, Colors.tealAccent],
        "screen": "meeting_scheduler",
        "description": "Schedule meetings with Rev. Pastor",
      },
    ];

    if (user.role == "admin") {
      menuItems.add({
        "title": "Admin Dashboard",
        "icon": LucideIcons.barChart3,
        "color": [Colors.red, Colors.redAccent],
        "screen": "admin",
        "description": "Church analytics and management",
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: _DashboardTitle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: menuItems.map((item) {
                    return GestureDetector(
                      onTap: () => _navigate(context, item["screen"] as String),
                      child: _MenuCard(item: item),
                    );
                  }).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: _QuickStatsFirestore(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.profilePhoto != null
                    ? NetworkImage(user.profilePhoto!)
                    : null,
                child: user.profilePhoto == null
                    ? Text(
                  user.name
                      .split(" ")
                      .map((e) => e[0])
                      .join(),
                  style: const TextStyle(
                      color: Colors.purple, fontSize: 18),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${user.name.split(" ")[0]}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.grey[600]),
                onPressed: () => _navigate(context, "profile"),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String screen) {
    switch (screen) {
      case "membership_request":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MembershipRequestScreen(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "events":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventsPage(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "donations":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DonationsScreen(user: user, onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "messages":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessagesScreen(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "prayer_requests":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PrayerRequests(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "meeting_scheduler":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MeetingScheduler(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "admin":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(onBack: () => Navigator.pop(context)),
          ),
        );
        break;
      case "profile":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  Scaffold(body: Center(child: Text("Profile Screen")))),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Screen not found")),
        );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onLogin: (User user) {}),
      ),
    );
  }
}

// Dashboard Title
class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Church Dashboard",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage your church activities and stay connected",
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// Menu Card
class _MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MenuCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4))
        ],
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: item["color"] as List<Color>),
                shape: BoxShape.circle,
              ),
              child: Icon(item["icon"] as IconData, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item["title"] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              item["description"] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Stats with Firestore
class _QuickStatsFirestore extends StatelessWidget {
  const _QuickStatsFirestore({super.key});

  @override
  Widget build(BuildContext context) {
    final membersRef = FirebaseFirestore.instance.collection('members');
    final attendanceRef = FirebaseFirestore.instance.collection('attendance');
    final donationsRef = FirebaseFirestore.instance.collection('donations');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: membersRef.snapshots(),
                builder: (context, snapshot) {
                  int totalMembers = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _StatCard(
                      title: "Total Members",
                      value: "$totalMembers",
                      colors: [Colors.purple, Colors.deepPurple]);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: attendanceRef.snapshots(),
                builder: (context, snapshot) {
                  double attendanceRate = 0;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    int total = snapshot.data!.docs.length;
                    int attended = snapshot.data!.docs
                        .where((doc) => doc['attended'] == true)
                        .length;
                    attendanceRate = total > 0 ? (attended / total * 100) : 0;
                  }
                  return _StatCard(
                      title: "This Week's Attendance",
                      value: "${attendanceRate.toStringAsFixed(1)}%",
                      colors: [Colors.blue, Colors.blueAccent]);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: donationsRef.snapshots(),
          builder: (context, snapshot) {
            double totalDonations = 0;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              totalDonations = snapshot.data!.docs.fold(0, (sum, doc) {
                return sum + (doc['amount'] ?? 0);
              });
            }
            return _StatCard(
                title: "Monthly Donations",
                value: "\$${totalDonations.toStringAsFixed(2)}",
                colors: [Colors.green, Colors.greenAccent]);
          },
        ),
      ],
    );
  }
}

// Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> colors;

  const _StatCard(
      {required this.title, required this.value, required this.colors, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
