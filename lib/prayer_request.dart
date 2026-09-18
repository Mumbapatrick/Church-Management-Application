import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================
// COLORS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color gold = Color(0xFFFFD700);

const Color backgroundWhite = Color(0xFFF8F7FC);

// ============================================================
// CATEGORY MODEL
// ============================================================

class PrayerCategory {
  final String value;
  final String label;
  final IconData icon;
  final List<Color> colors;

  const PrayerCategory({
    required this.value,
    required this.label,
    required this.icon,
    required this.colors,
  });
}

// ============================================================
// PRAYER REQUEST MODEL
// ============================================================

class PrayerRequest {
  final String id;
  final String name;
  final String category;
  final String title;
  final String description;
  final bool isAnonymous;
  final bool isUrgent;
  final String dateSubmitted;
  final String status;

  const PrayerRequest({
    required this.id,
    required this.name,
    required this.category,
    required this.title,
    required this.description,
    required this.isAnonymous,
    required this.isUrgent,
    required this.dateSubmitted,
    required this.status,
  });

  factory PrayerRequest.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();

    final Map<String, dynamic> data =
    rawData is Map<String, dynamic> ? rawData : {};

    return PrayerRequest(
      id: doc.id,
      name: data['name']?.toString() ?? 'Anonymous',
      category: data['category']?.toString() ?? 'general',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      isAnonymous: data['isAnonymous'] == true,
      isUrgent: data['isUrgent'] == true,
      dateSubmitted: data['dateSubmitted']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'title': title,
      'description': description,
      'isAnonymous': isAnonymous,
      'isUrgent': isUrgent,
      'dateSubmitted': dateSubmitted,
      'status': status,
    };
  }
}

// ============================================================
// PRAYER REQUEST PAGE
// ============================================================

class PrayerRequests extends StatefulWidget {
  final VoidCallback onBack;

  const PrayerRequests({
    super.key,
    required this.onBack,
  });

  @override
  State<PrayerRequests> createState() => _PrayerRequestsState();
}

// ============================================================
// STATE
// ============================================================

class _PrayerRequestsState extends State<PrayerRequests>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String? _selectedCategory;

  bool _isAnonymous = false;
  bool _isUrgent = false;
  bool _isSubmitting = false;

  // ==========================================================
  // CATEGORIES
  //
  // STRONGLY TYPED.
  // This prevents the IconData null/type problem that caused
  // the previous runtime error around _buildCategorySelector.
  // ==========================================================

  static const List<PrayerCategory> _categories = [
    PrayerCategory(
      value: 'personal',
      label: 'Personal',
      icon: Icons.person_rounded,
      colors: [
        purple,
        purpleLight,
      ],
    ),
    PrayerCategory(
      value: 'family',
      label: 'Family',
      icon: Icons.family_restroom_rounded,
      colors: [
        Color(0xFF0F766E),
        Color(0xFF2DD4BF),
      ],
    ),
    PrayerCategory(
      value: 'healing',
      label: 'Healing',
      icon: Icons.favorite_rounded,
      colors: [
        Color(0xFFDB2777),
        Color(0xFFF472B6),
      ],
    ),
    PrayerCategory(
      value: 'ministry',
      label: 'Ministry',
      icon: Icons.church_rounded,
      colors: [
        Color(0xFF2563EB),
        Color(0xFF60A5FA),
      ],
    ),
  ];

  // ==========================================================
  // LIFECYCLE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FA),
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // EVENTS-STYLE BACKGROUND
            // ==================================================

            Positioned.fill(
              child: _buildPageBackground(),
            ),

            // ==================================================
            // PAGE CONTENT
            // ==================================================

            Column(
              children: [
                _buildHeader(),
                _buildTabs(),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmitTab(),
                      _buildRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EVENTS-STYLE BACKGROUND
  // ============================================================

  Widget _buildPageBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8F5FC),
            Color(0xFFF3ECFA),
            Color(0xFFFFFBF0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ----------------------------------------------------
          // TOP LEFT PURPLE GLOW
          // ----------------------------------------------------

          Positioned(
            top: -120,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purple.withOpacity(0.08),
              ),
            ),
          ),

          // ----------------------------------------------------
          // TOP RIGHT GOLD GLOW
          // ----------------------------------------------------

          Positioned(
            top: -80,
            right: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.10),
              ),
            ),
          ),

          // ----------------------------------------------------
          // MIDDLE RIGHT PURPLE GLOW
          // ----------------------------------------------------

          Positioned(
            top: 330,
            right: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purpleLight.withOpacity(0.055),
              ),
            ),
          ),

          // ----------------------------------------------------
          // BOTTOM LEFT GOLD GLOW
          // ----------------------------------------------------

          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.06),
              ),
            ),
          ),

          // ----------------------------------------------------
          // BOTTOM RIGHT PURPLE GLOW
          // ----------------------------------------------------

          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purple.withOpacity(0.045),
              ),
            ),
          ),

          // ----------------------------------------------------
          // SOFT OVERLAY
          // ----------------------------------------------------

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.transparent,
                      Colors.white.withOpacity(0.10),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            purpleDark,
            purple,
            purpleLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),
          child: Row(
            children: [
              // ------------------------------------------------
              // BACK BUTTON
              // ------------------------------------------------

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius:
                  BorderRadius.circular(13),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.14),
                      borderRadius:
                      BorderRadius.circular(13),
                      border: Border.all(
                        color:
                        Colors.white.withOpacity(0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: purple,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Share your needs and stand together in prayer',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      color: Colors.white.withOpacity(0.96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),
          child: TabBar(
            controller: _tabController,

            indicatorColor: purple,

            indicatorWeight: 3,

            labelColor: purple,

            unselectedLabelColor:
            const Color(0xFF888888),

            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),

            tabs: const [
              Tab(
                icon: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                ),
                text: 'Submit Request',
              ),

              Tab(
                icon: Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                ),
                text: 'Prayer Requests',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT TAB
  // ============================================================

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        35,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: _buildFormCard(),
        ),
      ),
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius:
        BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],

        border: Border.all(
          color: purple.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==================================================
          // FORM HEADER
          // ==================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient:
                  const LinearGradient(
                    colors: [
                      purple,
                      purpleLight,
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit a Prayer Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Let our church family stand with you in prayer.',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ==================================================
          // TITLE
          // ==================================================

          _buildFieldLabel(
            'Prayer Request Title',
            required: true,
          ),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _titleController,
            hint: 'e.g. Prayer for my family',
            icon: Icons.title_rounded,
          ),

          const SizedBox(height: 18),

          // ==================================================
          // CATEGORY
          // ==================================================

          _buildFieldLabel(
            'Category',
            required: true,
          ),

          const SizedBox(height: 8),

          _buildCategorySelector(),

          const SizedBox(height: 18),

          // ==================================================
          // DESCRIPTION
          // ==================================================

          _buildFieldLabel(
            'Prayer Request Details',
            required: true,
          ),

          const SizedBox(height: 8),

          _buildTextField(
            controller:
            _descriptionController,
            hint:
            'Share what you would like us to pray about...',
            icon:
            Icons.description_rounded,
            maxLines: 6,
          ),

          const SizedBox(height: 18),

          // ==================================================
          // ANONYMOUS
          // ==================================================

          _buildOptionCard(
            icon:
            Icons.visibility_off_rounded,
            title:
            'Submit anonymously',
            subtitle:
            'Your name will not be displayed.',
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value;
              });
            },
          ),

          const SizedBox(height: 10),

          // ==================================================
          // URGENT
          // ==================================================

          _buildOptionCard(
            icon:
            Icons.priority_high_rounded,
            title:
            'Mark as urgent',
            subtitle:
            'Use this when the prayer need is especially urgent.',
            value: _isUrgent,
            activeColor:
            Colors.red.shade600,
            onChanged: (value) {
              setState(() {
                _isUrgent = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // ==================================================
          // SUBMIT BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
              _isSubmitting
                  ? null
                  : _handleSubmit,

              icon: Icon(
                _isSubmitting
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                size: 19,
              ),

              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : 'Submit Prayer Request',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w800,
                  fontSize: 13,
                ),
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor:
                Colors.white,
                disabledBackgroundColor:
                purple.withOpacity(0.5),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _buildFieldLabel(
      String label, {
        bool required = false,
      }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF333333),
          ),
        ),

        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight:
              FontWeight.w900,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,

      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 12,
        ),

        prefixIcon: Icon(
          icon,
          color: purple,
          size: 20,
        ),

        filled: true,

        fillColor:
        const Color(0xFFF9F7FC),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide:
          BorderSide(
            color:
            purple.withOpacity(0.08),
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide:
          const BorderSide(
            color: purple,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY SELECTOR
  // ============================================================

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,

      children:
      _categories.map(
            (category) {
          final bool selected =
              _selectedCategory ==
                  category.value;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory =
                    category.value;
              });
            },

            borderRadius:
            BorderRadius.circular(14),

            child: AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 150,
              ),

              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),

              decoration:
              BoxDecoration(
                color: selected
                    ? purple
                    : const Color(
                  0xFFF7F4FB,
                ),

                borderRadius:
                BorderRadius.circular(
                  14,
                ),

                border: Border.all(
                  color: selected
                      ? purple
                      : purple.withOpacity(
                    0.08,
                  ),
                ),
              ),

              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  // IMPORTANT:
                  // category.icon is guaranteed
                  // to be IconData.
                  Icon(
                    category.icon,
                    size: 17,
                    color: selected
                        ? Colors.white
                        : purple,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    category.label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(
                        0xFF444444,
                      ),
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // OPTION CARD
  // ============================================================

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
    onChanged,
    Color activeColor = purple,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),

      borderRadius:
      BorderRadius.circular(16),

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),

        decoration:
        BoxDecoration(
          color: value
              ? activeColor.withOpacity(
            0.07,
          )
              : const Color(0xFFF9F9FB),

          borderRadius:
          BorderRadius.circular(16),

          border: Border.all(
            color: value
                ? activeColor.withOpacity(
              0.25,
            )
                : const Color(
              0xFFEAEAEA,
            ),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,

              decoration:
              BoxDecoration(
                color:
                activeColor.withOpacity(
                  0.10,
                ),

                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),

              child: Icon(
                icon,
                color: activeColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),

            Switch(
              value: value,
              onChanged: onChanged,
              activeColor:
              activeColor,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REQUESTS TAB
  // ============================================================

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(
          'prayer_requests')
          .orderBy(
        'dateSubmitted',
        descending: true,
      )
          .snapshots(),

      builder:
          (context, snapshot) {
        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (snapshot.hasError) {
          return _buildErrorState(
            snapshot.error.toString(),
          );
        }

        // ------------------------------------------------------
        // LOADING
        // ------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(
              color: purple,
            ),
          );
        }

        // ------------------------------------------------------
        // DOCUMENTS
        // ------------------------------------------------------

        final requests =
            snapshot.data?.docs
                .map(
                  (doc) =>
                  PrayerRequest
                      .fromFirestore(
                    doc,
                  ),
            )
                .toList() ??
                [];

        // ------------------------------------------------------
        // EMPTY
        // ------------------------------------------------------

        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        // ------------------------------------------------------
        // RESPONSIVE GRID
        // ------------------------------------------------------

        return LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            final int columns;

            if (width >= 1100) {
              columns = 3;
            } else if (width >= 700) {
              columns = 2;
            } else {
              columns = 1;
            }

            return Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1250,
                ),

                child:
                GridView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    24,
                    20,
                    40,
                  ),

                  itemCount:
                  requests.length,

                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                    columns,

                    crossAxisSpacing:
                    16,

                    mainAxisSpacing:
                    16,

                    mainAxisExtent:
                    columns == 1
                        ? 390
                        : 365,
                  ),

                  itemBuilder:
                      (context, index) {
                    return _buildPrayerCard(
                      requests[index],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PRAYER CARD
  // ============================================================

  Widget _buildPrayerCard(
      PrayerRequest req,
      ) {
    final category =
    _getCategory(req.category);

    final colors =
        category.colors;

    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(24),

        border: Border.all(
          color: colors.first
              .withOpacity(0.08),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08),
            blurRadius: 22,
            offset:
            const Offset(0, 9),
          ),
        ],
      ),

      clipBehavior:
      Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==================================================
          // CARD HEADER
          // ==================================================

          Container(
            height: 105,
            width:
            double.infinity,

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
            ),

            child: Stack(
              children: [
                // --------------------------------------------
                // DECORATIVE CIRCLE
                // --------------------------------------------

                Positioned(
                  right: -25,
                  top: -40,

                  child: Container(
                    width: 125,
                    height: 125,

                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withOpacity(
                        0.09,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                  ),
                ),

                // --------------------------------------------
                // SECOND CIRCLE
                // --------------------------------------------

                Positioned(
                  right: 35,
                  bottom: -55,

                  child: Container(
                    width: 90,
                    height: 90,

                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withOpacity(
                        0.07,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                  ),
                ),

                // --------------------------------------------
                // CONTENT
                // --------------------------------------------

                Padding(
                  padding:
                  const EdgeInsets.all(
                    15,
                  ),

                  child: Row(
                    children: [
                      // --------------------------------------
                      // ICON
                      // --------------------------------------

                      Container(
                        width: 50,
                        height: 50,

                        decoration:
                        BoxDecoration(
                          color: Colors.white
                              .withOpacity(
                            0.95,
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),
                        ),

                        child: Icon(
                          category.icon,
                          color:
                          colors.first,
                          size: 24,
                        ),
                      ),

                      const SizedBox(
                        width: 11,
                      ),

                      // --------------------------------------
                      // CATEGORY + TITLE
                      // --------------------------------------

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child:
                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      8,
                                      vertical:
                                      4,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.18,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        20,
                                      ),
                                    ),

                                    child:
                                    Text(
                                      category
                                          .label,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,

                                      style:
                                      const TextStyle(
                                        color:
                                        Colors.white,
                                        fontSize:
                                        9,
                                        fontWeight:
                                        FontWeight
                                            .w800,
                                      ),
                                    ),
                                  ),
                                ),

                                // --------------------------------
                                // URGENT
                                // --------------------------------

                                if (req
                                    .isUrgent) ...[
                                  const SizedBox(
                                    width: 6,
                                  ),

                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      7,
                                      vertical:
                                      4,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color: Colors
                                          .red
                                          .withOpacity(
                                        0.9,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        20,
                                      ),
                                    ),

                                    child:
                                    const Row(
                                      mainAxisSize:
                                      MainAxisSize
                                          .min,
                                      children: [
                                        Icon(
                                          Icons
                                              .priority_high_rounded,
                                          color:
                                          Colors.white,
                                          size:
                                          11,
                                        ),

                                        SizedBox(
                                          width: 2,
                                        ),

                                        Text(
                                          'URGENT',
                                          style:
                                          TextStyle(
                                            color:
                                            Colors.white,
                                            fontSize:
                                            8,
                                            fontWeight:
                                            FontWeight
                                                .w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            Text(
                              req.title.isEmpty
                                  ? 'Prayer Request'
                                  : req.title,

                              maxLines: 2,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontSize:
                                17,
                                fontWeight:
                                FontWeight
                                    .w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // CARD BODY
          // ==================================================

          Expanded(
            child: Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                14,
                16,
                14,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  // ------------------------------------------
                  // USER + STATUS
                  // ------------------------------------------

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,

                        backgroundColor:
                        colors.first
                            .withOpacity(
                          0.10,
                        ),

                        child: Icon(
                          req.isAnonymous
                              ? Icons
                              .person_off_rounded
                              : Icons
                              .person_rounded,

                          color:
                          colors.first,

                          size: 16,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child: Text(
                          req.isAnonymous
                              ? 'Anonymous'
                              : req.name,

                          maxLines: 1,

                          overflow:
                          TextOverflow
                              .ellipsis,

                          style:
                          const TextStyle(
                            fontSize:
                            11,
                            fontWeight:
                            FontWeight
                                .w800,
                            color:
                            Color(
                              0xFF333333,
                            ),
                          ),
                        ),
                      ),

                      _buildStatusChip(
                        req.status,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // ------------------------------------------
                  // DESCRIPTION
                  // ------------------------------------------

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets
                        .all(
                      13,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFF9F7FC,
                      ),

                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),

                      border:
                      Border.all(
                        color: colors
                            .first
                            .withOpacity(
                          0.06,
                        ),
                      ),
                    ),

                    child: Text(
                      req.description
                          .isEmpty
                          ? 'No details provided.'
                          : req.description,

                      maxLines: 5,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF555555,
                        ),
                        fontSize:
                        11,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ------------------------------------------
                  // DATE + PRAY
                  // ------------------------------------------

                  Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_today_rounded,
                        size: 13,
                        color: Colors
                            .grey
                            .shade500,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          _formatDate(
                            req.dateSubmitted,
                          ),

                          style:
                          const TextStyle(
                            fontSize:
                            10,
                            color:
                            Color(
                              0xFF888888,
                            ),
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),

                      OutlinedButton.icon(
                        onPressed: () {
                          _showFeedback(
                            message:
                            'You prayed for "${req.title}".',
                            icon: Icons
                                .volunteer_activism_rounded,
                            color:
                            purple,
                          );
                        },

                        icon:
                        const Icon(
                          Icons
                              .volunteer_activism_rounded,
                          size: 15,
                        ),

                        label:
                        const Text(
                          'Pray',
                        ),

                        style:
                        OutlinedButton
                            .styleFrom(
                          foregroundColor:
                          colors.first,

                          side:
                          BorderSide(
                            color: colors
                                .first
                                .withOpacity(
                              0.3,
                            ),
                          ),

                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            12,
                            vertical:
                            8,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              11,
                            ),
                          ),

                          textStyle:
                          const TextStyle(
                            fontSize:
                            11,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY HELPERS
  // ============================================================

  PrayerCategory _getCategory(
      String category,
      ) {
    final normalized =
    category
        .toLowerCase()
        .trim();

    for (final item in _categories) {
      if (item.value ==
          normalized) {
        return item;
      }
    }

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------

    return const PrayerCategory(
      value: 'general',
      label: 'General',
      icon:
      Icons.volunteer_activism_rounded,
      colors: [
        purple,
        purpleLight,
      ],
    );
  }

  IconData _categoryIcon(
      String category,
      ) {
    return _getCategory(
      category,
    ).icon;
  }

  List<Color> _categoryColors(
      String category,
      ) {
    return _getCategory(
      category,
    ).colors;
  }

  String _categoryLabel(
      String category,
      ) {
    return _getCategory(
      category,
    ).label;
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
      String status,
      ) {
    Color color;
    IconData icon;
    String label;

    switch (
    status.toLowerCase()) {
      case 'praying':
        color = purple;
        icon =
            Icons.favorite_rounded;
        label = 'Praying';
        break;

      case 'answered':
        color =
            Colors.green.shade700;
        icon =
            Icons.check_circle_rounded;
        label = 'Answered';
        break;

      case 'pending':
        color =
            Colors.orange.shade700;
        icon =
            Icons.schedule_rounded;
        label = 'Pending';
        break;

      default:
        color =
            Colors.grey.shade600;
        icon =
            Icons.help_outline_rounded;
        label = 'Unknown';
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),

      decoration:
      BoxDecoration(
        color: color.withOpacity(
          0.09,
        ),

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),

          const SizedBox(
            width: 3,
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight:
              FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _handleSubmit() async {
    final title =
    _titleController.text.trim();

    final description =
    _descriptionController.text
        .trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (title.isEmpty ||
        description.isEmpty ||
        _selectedCategory == null) {
      _showFeedback(
        message:
        'Please complete all required fields.',
        icon:
        Icons.info_outline_rounded,
        color:
        Colors.orange.shade700,
      );

      return;
    }

    // ----------------------------------------------------------
    // PREVENT DUPLICATE SUBMISSION
    // ----------------------------------------------------------

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user =
          _auth.currentUser;

      final name = _isAnonymous
          ? 'Anonymous'
          : (user?.displayName ??
          user?.email ??
          'Unknown User');

      // --------------------------------------------------------
      // FIRESTORE
      // --------------------------------------------------------

      await _firestore
          .collection(
        'prayer_requests',
      )
          .add({
        'name': name,
        'category':
        _selectedCategory,
        'title': title,
        'description':
        description,
        'isAnonymous':
        _isAnonymous,
        'isUrgent':
        _isUrgent,
        'dateSubmitted':
        DateTime.now()
            .toIso8601String(),
        'status': 'pending',
      });

      if (!mounted) return;

      // --------------------------------------------------------
      // CLEAR FORM
      // --------------------------------------------------------

      _titleController.clear();

      _descriptionController
          .clear();

      setState(() {
        _selectedCategory =
        null;

        _isAnonymous =
        false;

        _isUrgent =
        false;

        _isSubmitting =
        false;
      });

      // --------------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------------

      _showFeedback(
        message:
        'Prayer request submitted successfully.',
        icon:
        Icons.check_circle_rounded,
        color:
        Colors.green.shade700,
      );

      // --------------------------------------------------------
      // GO TO REQUESTS
      // --------------------------------------------------------

      _tabController.animateTo(
        1,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting =
        false;
      });

      _showFeedback(
        message:
        'Unable to submit your prayer request. Please try again.',
        icon:
        Icons.error_outline_rounded,
        color:
        Colors.red.shade700,
      );
    }
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  void _showFeedback({
    required String message,
    required IconData icon,
    Color color = purple,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          margin:
          const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            20,
          ),

          backgroundColor:
          color,

          elevation: 8,

          duration:
          const Duration(
            seconds: 3,
          ),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),

          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.18,
                  ),
                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color:
                  Colors.white,
                  size: 18,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  message,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontWeight:
                    FontWeight.w700,
                    fontSize:
                    13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
      String value,
      ) {
    if (value.isEmpty) {
      return 'Date not available';
    }

    try {
      final date =
      DateTime.parse(
        value,
      ).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${months[date.month - 1]} '
          '${date.day}, '
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin:
        const EdgeInsets.all(25),

        padding:
        const EdgeInsets.all(30),

        decoration:
        BoxDecoration(
          color:
          Colors.white.withOpacity(
            0.96,
          ),

          borderRadius:
          BorderRadius.circular(
            24,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(
                0.07,
              ),

              blurRadius: 22,

              offset:
              const Offset(0, 8),
            ),
          ],
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 75,
              height: 75,

              decoration:
              BoxDecoration(
                color: purple
                    .withOpacity(
                  0.08,
                ),
                shape:
                BoxShape.circle,
              ),

              child:
              const Icon(
                Icons
                    .volunteer_activism_rounded,
                color: purple,
                size: 35,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'No Prayer Requests',
              style:
              TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'There are no prayer requests available yet.',
              textAlign:
              TextAlign.center,

              style: TextStyle(
                color:
                Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
      String error,
      ) {
    return Center(
      child: Container(
        margin:
        const EdgeInsets.all(25),

        padding:
        const EdgeInsets.all(25),

        decoration:
        BoxDecoration(
          color:
          Colors.white.withOpacity(
            0.96,
          ),

          borderRadius:
          BorderRadius.circular(
            20,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(
                0.06,
              ),
              blurRadius: 20,
              offset:
              const Offset(0, 8),
            ),
          ],
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color: Colors.red,
              size: 45,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Unable to load prayer requests',
              style:
              TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              error,
              textAlign:
              TextAlign.center,

              style: TextStyle(
                color:
                Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}