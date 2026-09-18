import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/animation.dart';
import 'model/user.dart';
import 'membershiprequests.dart';
import 'donation.dart';
import 'events.dart';
import 'devotion.dart';
import 'prayer_request.dart';
import 'meetingscheduler.dart';
import 'authscreen.dart';
import 'admindashboard.dart';

// ============================================================
// APP COLORS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);

const Color gold = Color(0xFFFFD700);
const Color backgroundWhite = Color(0xFFF8F7FC);

const Color textDark = Color(0xFF1E293B);
const Color textGrey = Color(0xFF64748B);

// ============================================================
// DASHBOARD
// ============================================================

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

  List<Map<String, dynamic>> _menuItems() {
    final items = <Map<String, dynamic>>[
      {
        "title": "Membership Requests",
        "icon": Icons.person_add_rounded,
        "screen": "membership_request",
        "description": "Request to become a member",
        "gradient": const LinearGradient(
          colors: [Color(0xFF8A2387), Color(0xFFE94057)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        "title": "Events",
        "icon": Icons.calendar_today_rounded,
        "screen": "events",
        "description": "View upcoming church events",
        "gradient": const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        "title": "Donations",
        "icon": Icons.attach_money_rounded,
        "screen": "donations",
        "description": "Make tithes and offerings",
        "gradient": const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        "title": "Messages",
        "icon": Icons.chat_bubble_outline_rounded,
        "screen": "messages",
        "description": "Devotionals and announcements",
        "gradient": const LinearGradient(
          colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        "title": "Prayer Requests",
        "icon": Icons.favorite_border_rounded,
        "screen": "prayer_requests",
        "description": "Submit and view prayer requests",
        "gradient": const LinearGradient(
          colors: [Color(0xFFFF007F), Color(0xFFFF758C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        "title": "Meet with Pastor",
        "icon": Icons.access_time_rounded,
        "screen": "meeting_scheduler",
        "description": "Schedule meetings with Rev. Pastor",
        "gradient": const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];

    if (user.role == "admin") {
      items.add({
        "title": "Admin Dashboard",
        "icon": Icons.insights_rounded,
        "screen": "admin",
        "description": "Church analytics & management",
        "gradient": const LinearGradient(
          colors: [Color(0xFF4B1248), Color(0xFFF0C27B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _menuItems();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4C087A),
                Color(0xFF6A0DAD),
                Color(0xFF8B5CF6),
                Color(0xFFFFD700),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1250),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const _DashboardTitle(),
                              const SizedBox(height: 24),
                              _buildMenuGrid(context, menuItems),
                              const SizedBox(height: 28),
                              const _DashboardFooter(),
                            ],
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
      ),
    );
  }

  Widget _buildMenuGrid(
      BuildContext context,
      List<Map<String, dynamic>> menuItems,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 900;
        int columns = isDesktop ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isDesktop ? 16 : 14,
            mainAxisSpacing: isDesktop ? 16 : 14,
            childAspectRatio: isDesktop ? 1.20 : 0.85,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return ReusableEventCard(
              index: index,
              onTap: () => _navigate(context, item["screen"] as String),
              child: _MenuCard(item: item),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final firstName = user.name.trim().isNotEmpty
        ? user.name.trim().split(" ").first
        : "User";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, purpleLight],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: user.profilePhoto != null &&
                      user.profilePhoto!.isNotEmpty
                      ? Image.network(
                    user.profilePhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(firstName),
                  )
                      : _initials(firstName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back",
                      style: GoogleFonts.plusJakartaSans(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderButton(
                icon: Icons.settings_rounded,
                tooltip: "Profile",
                onTap: () => _navigate(context, "profile"),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.logout_rounded,
                tooltip: "Logout",
                isDanger: true,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "U",
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String screen) {
    Widget? targetPage;

    switch (screen) {
      case "membership_request":
        targetPage = MembershipRequestScreen(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "events":
        targetPage = EventsPage(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "donations":
        targetPage = DonationsScreen(
          user: user,
          onBack: () => Navigator.pop(context),
        );
        break;
      case "messages":
        targetPage = MessagesScreen(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "prayer_requests":
        targetPage = PrayerRequests(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "meeting_scheduler":
        targetPage = MeetingScheduler(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "admin":
        targetPage = AdminDashboard(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "profile":
        targetPage = Scaffold(
          backgroundColor: backgroundWhite,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: textDark,
            title: Text(
              "Profile",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(25),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                "Profile Screen",
                style: GoogleFonts.plusJakartaSans(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: purpleDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              "Screen not found",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
    }

    if (targetPage != null) {
      Navigator.push(context, SmoothPageRoute(page: targetPage));
    }
  }

  void _logout(BuildContext context) {
    if (onLogout != null) {
      onLogout!();
      return;
    }
    Navigator.pushReplacement(
      context,
      SmoothPageRoute(
        page: AuthScreen(onLogin: (User user) {}),
      ),
    );
  }
}

// ============================================================
// CENTERED DASHBOARD TITLE
// ============================================================

class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Church Dashboard",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Manage your church activities and stay connected",
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.white.withOpacity(0.92),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CENTER-ALIGNED MENU CARD
// ============================================================

class _MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final LinearGradient gradient = item["gradient"] as LinearGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Icon Container
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item["icon"] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Text Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item["title"] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["description"] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Center Bottom Arrow Button
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HEADER BUTTON
// ============================================================

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDanger;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : purple;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: isDanger
                  ? Colors.red.withOpacity(0.08)
                  : const Color(0xFFF4ECFA),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.08)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Developed by ",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: "Roam Quest Technologies",
                    style: GoogleFonts.plusJakartaSans(
                      color: gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}