import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewReportsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ViewReportsScreen({super.key, required this.onBack});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  int totalMembers = 0;
  int totalEvents = 0;
  double totalDonations = 0;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final membersSnap = await FirebaseFirestore.instance.collection('members').get();
    final eventsSnap = await FirebaseFirestore.instance.collection('events').get();
    final donationsSnap = await FirebaseFirestore.instance.collection('donations').get();

    double donationSum = 0;
    for (var doc in donationsSnap.docs) {
      donationSum += (doc['amount'] ?? 0);
    }

    setState(() {
      totalMembers = membersSnap.docs.length;
      totalEvents = eventsSnap.docs.length;
      totalDonations = donationSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Analytics"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _reportCard("Total Members", totalMembers.toString(), Colors.purple),
                _reportCard("Total Events", totalEvents.toString(), Colors.blue),
                _reportCard("Donations", "\$${totalDonations.toStringAsFixed(2)}", Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // Example: Monthly Attendance Chart
            const Text("Monthly Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 70, color: Colors.purple)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 50, color: Colors.purple)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 80, color: Colors.purple)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 60, color: Colors.purple)]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example: Event Category Pie Chart
            const Text("Event Categories", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 40, color: Colors.blue, title: "Service"),
                    PieChartSectionData(value: 20, color: Colors.green, title: "Outreach"),
                    PieChartSectionData(value: 30, color: Colors.orange, title: "Conference"),
                    PieChartSectionData(value: 10, color: Colors.purple, title: "Other"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
