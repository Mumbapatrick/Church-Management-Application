import 'dart:async';

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

  const AdminDashboard({
    super.key,
    required this.onBack,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

// ============================================================
// COLORS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);

const Color gold = Color(0xFFFFD700);
const Color backgroundWhite = Color(0xFFF8F7FC);

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _membersSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _donationsSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _eventsSubscription;

  int _totalMembers = 0;
  double _totalDonations = 0.0;
  int _upcomingEvents = 0;

  bool _loading = true;
  bool _refreshing = false;

  String? _firestoreError;

  @override
  void initState() {
    super.initState();
    _startFirestoreListeners();
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _donationsSubscription?.cancel();
    _eventsSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // PARSE EVENT DATE + TIME
  // ============================================================

  DateTime? _parseEventDateTime(
      Map<String, dynamic> data) {
    // ----------------------------------------------------------
    // 1. First support a Timestamp "date" field if one exists.
    // ----------------------------------------------------------

    final dynamic rawDate = data["date"];

    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }

    if (rawDate is DateTime) {
      return rawDate;
    }

    // ----------------------------------------------------------
    // 2. Your CreateEventScreen uses:
    //
    // fromDate = "2026-08-11"
    // fromTime = "02:30 PM"
    //
    // ----------------------------------------------------------

    final String? fromDate =
    data["fromDate"]?.toString().trim();

    final String? fromTime =
    data["fromTime"]?.toString().trim();

    if (fromDate == null ||
        fromDate.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // Parse date
    // ----------------------------------------------------------

    DateTime? date;

    try {
      date = DateTime.parse(fromDate);
    } catch (_) {
      return null;
    }

    // ----------------------------------------------------------
    // If there is no time, use beginning of the day.
    // ----------------------------------------------------------

    if (fromTime == null ||
        fromTime.isEmpty) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    // ----------------------------------------------------------
    // Parse "02:30 PM"
    // ----------------------------------------------------------

    final RegExp timeRegex = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    );

    final Match? match =
    timeRegex.firstMatch(fromTime);

    if (match == null) {
      // Try normal 24-hour format as fallback.
      final parts =
      fromTime.split(':');

      if (parts.length >= 2) {
        final hour =
        int.tryParse(parts[0]);

        final minute =
        int.tryParse(
          parts[1].replaceAll(
            RegExp(r'[^0-9]'),
            '',
          ),
        );

        if (hour != null &&
            minute != null) {
          return DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
        }
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    int hour =
    int.parse(match.group(1)!);

    final int minute =
    int.parse(match.group(2)!);

    final String period =
    match.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  // ============================================================
  // COUNT UPCOMING EVENTS
  // ============================================================

  int _countUpcomingEvents(
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
      documents) {
    final DateTime now = DateTime.now();

    int upcoming = 0;

    for (final doc in documents) {
      final data = doc.data();

      final DateTime? eventDate =
      _parseEventDateTime(data);

      if (eventDate == null) {
        debugPrint(
          "Event ${doc.id} has no valid date/time. "
              "Data: $data",
        );
        continue;
      }

      debugPrint(
        "Event ${doc.id}: "
            "${data["title"]} -> "
            "$eventDate",
      );

      if (eventDate.isAfter(now)) {
        upcoming++;
      }
    }

    return upcoming;
  }

  // ============================================================
  // FIRESTORE LISTENERS
  // ============================================================

  void _startFirestoreListeners() {
    _firestoreError = null;

    // ==========================================================
    // MEMBERS
    // ==========================================================

    _membersSubscription = _firestore
        .collection("members")
        .snapshots()
        .listen(
          (snapshot) {
        if (!mounted) return;

        setState(() {
          _totalMembers =
              snapshot.docs.length;

          _loading = false;
        });
      },
      onError: (error) {
        debugPrint(
          "Members Firestore Error: $error",
        );

        if (!mounted) return;

        setState(() {
          _firestoreError =
          "Unable to retrieve members data.";

          _loading = false;
        });
      },
    );

    // ==========================================================
    // DONATIONS
    // ==========================================================

    _donationsSubscription = _firestore
        .collection("donations")
        .snapshots()
        .listen(
          (snapshot) {
        double total = 0.0;

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final dynamic amount =
          data["amount"];

          if (amount is num) {
            total += amount.toDouble();
          } else if (amount is String) {
            total +=
                double.tryParse(amount) ??
                    0.0;
          }
        }

        if (!mounted) return;

        setState(() {
          _totalDonations = total;
          _loading = false;
        });
      },
      onError: (error) {
        debugPrint(
          "Donations Firestore Error: $error",
        );

        if (!mounted) return;

        setState(() {
          _firestoreError =
          "Unable to retrieve donations data.";
        });
      },
    );

    // ==========================================================
    // EVENTS
    // ==========================================================

    _eventsSubscription = _firestore
        .collection("events")
        .snapshots()
        .listen(
          (snapshot) {
        if (!mounted) return;

        final int upcoming =
        _countUpcomingEvents(
          snapshot.docs,
        );

        setState(() {
          _upcomingEvents = upcoming;
          _loading = false;
        });

        debugPrint(
          "Total events: ${snapshot.docs.length}",
        );

        debugPrint(
          "Upcoming events: $upcoming",
        );
      },
      onError: (error) {
        debugPrint(
          "Events Firestore Error: $error",
        );

        if (!mounted) return;

        setState(() {
          _firestoreError =
          "Unable to retrieve events data.";
        });
      },
    );
  }

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;

    if (mounted) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      debugPrint(
        "Refreshing dashboard data...",
      );

      final membersSnap =
      await _firestore
          .collection("members")
          .get(
        const GetOptions(
          source:
          Source.server,
        ),
      );

      final donationsSnap =
      await _firestore
          .collection("donations")
          .get(
        const GetOptions(
          source:
          Source.server,
        ),
      );

      final eventsSnap =
      await _firestore
          .collection("events")
          .get(
        const GetOptions(
          source:
          Source.server,
        ),
      );

      // ========================================================
      // DONATIONS
      // ========================================================

      double donations = 0.0;

      for (final doc
      in donationsSnap.docs) {
        final data = doc.data();

        final dynamic amount =
        data["amount"];

        if (amount is num) {
          donations +=
              amount.toDouble();
        } else if (amount is String) {
          donations +=
              double.tryParse(amount) ??
                  0.0;
        }
      }

      // ========================================================
      // EVENTS
      // ========================================================

      final int upcoming =
      _countUpcomingEvents(
        eventsSnap.docs,
      );

      debugPrint(
        "Refresh complete.",
      );

      debugPrint(
        "Members: ${membersSnap.docs.length}",
      );

      debugPrint(
        "Donations: $donations",
      );

      debugPrint(
        "Events total: ${eventsSnap.docs.length}",
      );

      debugPrint(
        "Upcoming events: $upcoming",
      );

      if (!mounted) return;

      setState(() {
        _totalMembers =
            membersSnap.docs.length;

        _totalDonations = donations;

        _upcomingEvents = upcoming;

        _firestoreError = null;

        _loading = false;
      });

      // Small delay makes the refresh state
      // visible to the user even on fast connections.
      await Future.delayed(
        const Duration(
          milliseconds: 400,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        "Dashboard refresh Firestore Error: "
            "${e.code} - ${e.message}",
      );

      if (!mounted) return;

      setState(() {
        _firestoreError =
        "Firestore error: ${e.message}";
      });
    } catch (e) {
      debugPrint(
        "Dashboard refresh error: $e",
      );

      if (!mounted) return;

      setState(() {
        _firestoreError =
        "Unable to refresh dashboard.";
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _refreshing = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // ======================================================
        // AUTH-STYLE PURPLE + GOLD BACKGROUND
        // ======================================================

        decoration:
        const BoxDecoration(
          gradient:
          LinearGradient(
            colors: [
              Color(0xFF4C087A),
              Color(0xFF6A0DAD),
              Color(0xFF8B5CF6),
              Color(0xFFFFD700),
            ],
            stops: [
              0.0,
              0.35,
              0.70,
              1.0,
            ],
            begin:
            Alignment.topLeft,
            end:
            Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // =================================================
              // ONLY TOP BAR
              // =================================================

              _buildTopBar(),

              // =================================================
              // DASHBOARD CONTENT
              // =================================================

              Expanded(
                child:
                RefreshIndicator(
                  onRefresh:
                  _refreshDashboard,
                  color: purple,
                  backgroundColor:
                  Colors.white,
                  child:
                  SingleChildScrollView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child:
                      ConstrainedBox(
                        constraints:
                        const BoxConstraints(
                          maxWidth: 1250,
                        ),
                        child:
                        Padding(
                          padding:
                          const EdgeInsets
                              .fromLTRB(
                            20,
                            24,
                            20,
                            40,
                          ),
                          child:
                          Column(
                            children: [
                              if (_firestoreError !=
                                  null)
                                _buildFirestoreError(),

                              if (_firestoreError !=
                                  null)
                                const SizedBox(
                                  height: 18,
                                ),

                              _buildMetricsGrid(),

                              const SizedBox(
                                height: 24,
                              ),

                              _buildAnalyticsSection(),

                              const SizedBox(
                                height: 24,
                              ),

                              _buildQuickActions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.12),
            blurRadius: 18,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1250,
          ),
          child: Row(
            children: [
              // BACK
              _buildTopBarButton(
                icon:
                Icons.arrow_back_rounded,
                onTap: widget.onBack,
              ),

              const SizedBox(
                width: 12,
              ),

              // APP ICON
              Container(
                width: 43,
                height: 43,
                decoration:
                BoxDecoration(
                  gradient:
                  const LinearGradient(
                    colors: [
                      purple,
                      purpleLight,
                    ],
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple
                          .withOpacity(
                        0.25,
                      ),
                      blurRadius: 10,
                      offset:
                      const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child:
                const Icon(
                  Icons
                      .admin_panel_settings_rounded,
                  color:
                  Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // TITLE
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      "Admin Dashboard",
                      style:
                      TextStyle(
                        fontSize: 19,
                        fontWeight:
                        FontWeight
                            .w800,
                        color:
                        Color(
                          0xFF202124,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      "Church Management",
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF777777,
                        ),
                        fontWeight:
                        FontWeight
                            .w500,
                      ),
                    ),
                  ],
                ),
              ),

              // REFRESH
              _buildRefreshButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _buildRefreshButton() {
    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: _refreshing
            ? null
            : _refreshDashboard,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 200,
          ),
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration:
          BoxDecoration(
            color: _refreshing
                ? const Color(
              0xFFF0E8F8,
            )
                : const Color(
              0xFFF4ECFA,
            ),
            borderRadius:
            BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color:
              purple.withOpacity(
                0.08,
              ),
            ),
          ),
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              if (_refreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: purple,
                  ),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  color: purple,
                  size: 21,
                ),

              if (_refreshing) ...[
                const SizedBox(
                  width: 8,
                ),
                const Text(
                  "Refreshing...",
                  style:
                  TextStyle(
                    color: purple,
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR BUTTON
  // ============================================================

  Widget _buildTopBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        child: Container(
          width: 43,
          height: 43,
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFF4ECFA,
            ),
            borderRadius:
            BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color:
              purple.withOpacity(
                0.08,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: purple,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIRESTORE ERROR
  // ============================================================

  Widget _buildFirestoreError() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(0.96),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(
            0xFFFECACA,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08),
            blurRadius: 12,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFFE4E4,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child:
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
              Color(
                0xFFDC2626,
              ),
              size: 21,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Text(
              _firestoreError!,
              style:
              const TextStyle(
                color:
                Color(
                  0xFFB91C1C,
                ),
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSIVE COLUMNS
  // DESKTOP = 3
  // PHONE/TABLET = 2
  // ============================================================

  int _getCrossAxisCount(
      double width) {
    if (width >= 900) {
      return 3;
    }

    return 2;
  }

  // ============================================================
  // METRICS
  // ============================================================

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final columns =
        _getCrossAxisCount(
          constraints.maxWidth,
        );

        final cards = [
          _buildMetricCard(
            title: "Total Members",
            value:
            _totalMembers.toString(),
            icon:
            Icons.people_alt_rounded,
            colors: const [
              purple,
              purpleLight,
            ],
          ),

          _buildMetricCard(
            title:
            "Monthly Donations",
            value:
            "KES ${_totalDonations.toStringAsFixed(2)}",
            icon: Icons
                .volunteer_activism_rounded,
            colors: const [
              Color(0xFF047857),
              Color(0xFF34D399),
            ],
          ),

          _buildMetricCard(
            title:
            "Upcoming Events",
            value:
            _upcomingEvents.toString(),
            icon: Icons
                .event_available_rounded,
            colors: const [
              Color(0xFFEA580C),
              Color(0xFFFB923C),
            ],
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          itemCount:
          cards.length,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
            columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
            columns == 2
                ? 1.28
                : 1.45,
          ),
          itemBuilder:
              (context, index) {
            return cards[index];
          },
        );
      },
    );
  }

  // ============================================================
  // METRIC CARD
  // ============================================================

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return _AnimatedCard(
      child: Container(
        decoration:
        BoxDecoration(
          gradient:
          LinearGradient(
            colors: colors,
            begin:
            Alignment.topLeft,
            end:
            Alignment.bottomRight,
          ),
          borderRadius:
          BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: Colors.white
                .withOpacity(0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first
                  .withOpacity(
                0.28,
              ),
              blurRadius: 18,
              offset:
              const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        padding:
        const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
              BoxDecoration(
                color: Colors.white
                    .withOpacity(
                  0.18,
                ),
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color: Colors.white
                      .withOpacity(
                    0.18,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color:
                Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(
              height: 11,
            ),

            Text(
              title,
              textAlign:
              TextAlign.center,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              value,
              textAlign:
              TextAlign.center,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 22,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Widget _buildAnalyticsSection() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final desktop =
            constraints.maxWidth >=
                900;

        final attendance =
        _buildChartCard(
          title:
          "Monthly Attendance",
          icon:
          Icons.people_alt_rounded,
          colors: const [
            purple,
            purpleLight,
          ],
        );

        final donations =
        _buildChartCard(
          title:
          "Monthly Donations",
          icon:
          Icons.payments_rounded,
          colors: const [
            Color(0xFF047857),
            Color(0xFF34D399),
          ],
        );

        if (desktop) {
          return Row(
            children: [
              Expanded(
                child:
                attendance,
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child:
                donations,
              ),
            ],
          );
        }

        return Column(
          children: [
            attendance,
            const SizedBox(
              height: 16,
            ),
            donations,
          ],
        );
      },
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      width: double.infinity,
      height: 245,
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(0.96),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.10),
            blurRadius: 18,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      padding:
      const EdgeInsets.all(19),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  gradient:
                  LinearGradient(
                    colors: colors,
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF202124,
                    ),
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: colors.first
                      .withOpacity(
                    0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  "Coming Soon",
                  style:
                  TextStyle(
                    color:
                    colors.first,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Expanded(
            child: Container(
              width:
              double.infinity,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF8F7FC,
                ),
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              child:
              Center(
                child:
                Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    Icon(
                      Icons
                          .analytics_outlined,
                      size: 42,
                      color: colors
                          .first
                          .withOpacity(
                        0.25,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      "Monthly data will appear here",
                      style:
                      TextStyle(
                        color:
                        Colors.grey
                            .shade500,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(0.96),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.10),
            blurRadius: 18,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                BoxDecoration(
                  gradient:
                  const LinearGradient(
                    colors: [
                      purple,
                      purpleLight,
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                const Icon(
                  Icons.apps_rounded,
                  color:
                  Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      "Quick Actions",
                      style:
                      TextStyle(
                        fontSize: 19,
                        fontWeight:
                        FontWeight
                            .w800,
                        color:
                        Color(
                          0xFF202124,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      "Access church management functions",
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF777777,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          LayoutBuilder(
            builder:
                (context, constraints) {
              final columns =
              _getCrossAxisCount(
                constraints.maxWidth,
              );

              final actions = [
                _buildActionButton(
                  context,
                  Icons
                      .people_alt_rounded,
                  "Members Directory",
                  const [
                    purple,
                    purpleLight,
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberDirectory(
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                              onSelectMember:
                                  (member) {
                                debugPrint(
                                  "Selected: ${member.name}",
                                );
                              },
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .person_add_alt_1_rounded,
                  "Add Member",
                  const [
                    Color(
                      0xFF7C3AED,
                    ),
                    Color(
                      0xFFA78BFA,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMemberScreen(
                              mode:
                              MemberFormMode
                                  .add,
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                              onSave:
                                  (member) async {
                                await _firestore
                                    .collection(
                                  "members",
                                )
                                    .add(
                                  member.toMap(),
                                );
                              },
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .assignment_rounded,
                  "Membership Requests",
                  const [
                    Color(
                      0xFFDC2626,
                    ),
                    Color(
                      0xFFF87171,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminMembershipRequests(
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons.event_rounded,
                  "Create Event",
                  const [
                    Color(
                      0xFF2563EB,
                    ),
                    Color(
                      0xFF60A5FA,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateEventScreen(
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .bar_chart_rounded,
                  "View Reports",
                  const [
                    Color(
                      0xFF059669,
                    ),
                    Color(
                      0xFF34D399,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewReportsScreen(
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .message_rounded,
                  "Send Message",
                  const [
                    Color(
                      0xFFEA580C,
                    ),
                    Color(
                      0xFFFB923C,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SendMessageScreen(
                              onBack: () =>
                                  Navigator.pop(
                                    context,
                                  ),
                            ),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .volunteer_activism_rounded,
                  "Prayer Requests",
                  const [
                    Color(
                      0xFF0F766E,
                    ),
                    Color(
                      0xFF2DD4BF,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminPrayerRequests(),
                      ),
                    );
                  },
                ),

                _buildActionButton(
                  context,
                  Icons
                      .schedule_rounded,
                  "Meeting Schedules",
                  const [
                    Color(
                      0xFF4338CA,
                    ),
                    Color(
                      0xFF818CF8,
                    ),
                  ],
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const AdminMeetingSchedule(),
                      ),
                    );
                  },
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount:
                actions.length,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                  columns,
                  crossAxisSpacing:
                  14,
                  mainAxisSpacing:
                  14,
                  childAspectRatio:
                  columns == 2
                      ? 1.20
                      : 1.35,
                ),
                itemBuilder:
                    (context, index) {
                  return actions[
                  index];
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      String label,
      List<Color> colors,
      VoidCallback onPressed,
      ) {
    return _AnimatedCard(
      onTap: onPressed,
      child: Container(
        decoration:
        BoxDecoration(
          gradient:
          LinearGradient(
            colors: colors,
            begin:
            Alignment.topLeft,
            end:
            Alignment.bottomRight,
          ),
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white
                .withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first
                  .withOpacity(
                0.22,
              ),
              blurRadius: 12,
              offset:
              const Offset(0, 6),
            ),
          ],
        ),
        padding:
        const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width: 49,
              height: 49,
              decoration:
              BoxDecoration(
                color: Colors.white
                    .withOpacity(
                  0.17,
                ),
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color: Colors.white
                      .withOpacity(
                    0.16,
                  ),
                ),
              ),
              child:
              Icon(
                icon,
                color:
                Colors.white,
                size: 25,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              label,
              textAlign:
              TextAlign.center,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED CARD
// ============================================================

class _AnimatedCard
    extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedCard({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedCard> createState() =>
      _AnimatedCardState();
}

class _AnimatedCardState
    extends State<_AnimatedCard> {
  bool _pressed = false;

  @override
  Widget build(
      BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,

      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() {
            _pressed = true;
          });
        }
      },

      onExit: (_) {
        if (widget.onTap != null) {
          setState(() {
            _pressed = false;
          });
        }
      },

      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) {
            setState(() {
              _pressed = true;
            });
          }
        },

        onTapUp: (_) {
          if (widget.onTap != null) {
            setState(() {
              _pressed = false;
            });
          }
        },

        onTapCancel: () {
          if (widget.onTap != null) {
            setState(() {
              _pressed = false;
            });
          }
        },

        onTap:
        widget.onTap,

        child: AnimatedScale(
          scale:
          _pressed ? 0.97 : 1.0,
          duration:
          const Duration(
            milliseconds: 120,
          ),
          child:
          widget.child,
        ),
      ),
    );
  }
}