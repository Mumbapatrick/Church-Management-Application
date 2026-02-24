import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordprayer/adminmembershiprequest.dart';
import 'addmember.dart';
import 'eventcreation.dart';
import 'viewreports.dart';
import 'sendmessage.dart';
import 'adminprayerrequest.dart';
import 'adminmeetingschedule.dart';
import 'membersdirectory.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onBack;
  const AdminDashboard({super.key, required this.onBack});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardMetrics();
  }

  // Fetch metrics from Firestore safely
  Future<List<dynamic>> _fetchDashboardMetrics() async {
    final membersSnap =
    await FirebaseFirestore.instance.collection('members').get();
    final donationsSnap =
    await FirebaseFirestore.instance.collection('donations').get();
    final eventsSnap =
    await FirebaseFirestore.instance.collection('events').get();

    int totalMembers = membersSnap.docs.length;

    double totalDonations = donationsSnap.docs.fold(
        0.0,
            (sum, doc) =>
        sum +
            ((doc.data().containsKey('amount') ? doc['amount'] : 0) as num)
                .toDouble());

    int upcomingEvents = eventsSnap.docs.length;

    return [totalMembers, totalDonations, upcomingEvents];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FutureBuilder<List<dynamic>>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Text("Error loading dashboard data");
                        }

                        final metrics = snapshot.data!;
                        final totalMembers = metrics[0] as int;
                        final totalDonations = metrics[1] as double;
                        final upcomingEvents = metrics[2] as int;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildMetricCard("Total Members", "$totalMembers",
                                "Live count", Colors.purple),
                            _buildMetricCard(
                                "Monthly Donations",
                                "\$${totalDonations.toStringAsFixed(2)}",
                                "Live data",
                                Colors.green),
                            _buildMetricCard("Upcoming Events",
                                "$upcomingEvents", "This month", Colors.orange),
                            _buildMetricCard("Attendance Rate", "Live",
                                "Live updates", Colors.blue),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildChartCard("Monthly Attendance", Colors.purple),
                    const SizedBox(height: 20),
                    _buildChartCard("Monthly Donations", Colors.blue),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                "Admin Dashboard",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Church Management & Analytics",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String subtitle, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 200, child: Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionButton(
              context,
              Icons.people,
              "Members Directory",
              Colors.purple,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberDirectory(
                    onBack: () => Navigator.pop(context),
                    onSelectMember: (member) =>
                        debugPrint("Selected: ${member.name}"),
                  ),
                ),
              ),
            ),
            _buildActionButton(
              context,
              Icons.person_add,
              "Add Member",
              Colors.purple,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMemberScreen(
                    mode: MemberFormMode.add,
                    onBack: () => Navigator.pop(context),
                    onSave: (member) => FirebaseFirestore.instance
                        .collection('members')
                        .add(member.toMap()),
                  ),
                ),
              ),
            ),
            _buildActionButton(
              context,
              Icons.request_page,
              "Membership Requests",
              Colors.red,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AdminMembershipRequests(onBack: () => Navigator.pop(context))),
              ),
            ),
            _buildActionButton(
              context,
              Icons.event,
              "Create Event",
              Colors.blue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CreateEventScreen(onBack: () => Navigator.pop(context))),
              ),
            ),
            _buildActionButton(
              context,
              Icons.bar_chart,
              "View Reports",
              Colors.green,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ViewReportsScreen(onBack: () => Navigator.pop(context))),
              ),
            ),
            _buildActionButton(
              context,
              Icons.message,
              "Send Message",
              Colors.orange,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        SendMessageScreen(onBack: () => Navigator.pop(context))),
              ),
            ),
            _buildActionButton(
              context,
              Icons.volunteer_activism,
              "Prayer Requests",
              Colors.teal,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminPrayerRequests()),
              ),
            ),
            _buildActionButton(
              context,
              Icons.schedule,
              "Meeting Schedules",
              Colors.indigo,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminMeetingSchedule()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, Color color,
      {VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(20),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
