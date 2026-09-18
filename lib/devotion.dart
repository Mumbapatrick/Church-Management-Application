import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/message.dart';

// ============================================================
// COLORS
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color gold = Color(0xFFFFD700);
const Color backgroundWhite = Color(0xFFF8F7FC);

// ============================================================
// MESSAGES SCREEN
// ============================================================

class MessagesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MessagesScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedCategory = 'all';

  final List<String> categories = [
    'all',
    'announcement',
    'devotional',
    'prayer',
    'newsletter',
  ];

  // ==========================================================
  // CATEGORY COLORS
  // ==========================================================

  List<Color> _categoryColors(String category) {
    return const [
      purpleDark,
      purple,
      purpleLight,
    ];
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'announcement':
        return Icons.campaign_rounded;

      case 'devotional':
        return Icons.menu_book_rounded;

      case 'prayer':
        return Icons.volunteer_activism_rounded;

      case 'newsletter':
        return Icons.article_rounded;

      default:
        return Icons.mail_rounded;
    }
  }

  // ==========================================================
  // CATEGORY LABEL
  // ==========================================================

  String _categoryLabel(String category) {
    if (category == 'all') {
      return 'All Messages';
    }

    if (category.isEmpty) {
      return 'Message';
    }

    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  // ==========================================================
  // DATE FORMATTER HELPER
  // ==========================================================

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Container(
        color: backgroundWhite,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryFilters(),
              Expanded(
                child: _buildMessages(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

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
              // BACK BUTTON
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
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

              // ICON
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: purple,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              // TITLE
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages & Devotionals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Stay connected with church messages and devotionals',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  // ==========================================================
  // CATEGORY FILTERS
  // ==========================================================

  Widget _buildCategoryFilters() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final bool selected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    category,
                    selected,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER CHIP
  // ==========================================================

  Widget _buildFilterChip(
      String category,
      bool selected,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = category;
          });
        },
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [
                purpleDark,
                purpleLight,
              ],
            )
                : null,
            color: selected ? null : const Color(0xFFF5F2FA),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? Colors.transparent : purple.withOpacity(0.08),
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: purple.withOpacity(0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _categoryIcon(category),
                size: 16,
                color: selected ? Colors.white : purple,
              ),
              const SizedBox(width: 7),
              Text(
                _categoryLabel(category),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF555555),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGES STREAM
  // ==========================================================

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy(
        'timestamp',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: purple,
            ),
          );
        }

        final messages = snapshot.data?.docs
            .map((doc) {
          final data = doc.data();

          if (data is! Map<String, dynamic>) {
            return null;
          }

          return Message.fromMap(
            data,
            doc.id,
          );
        })
            .whereType<Message>()
            .where(
              (msg) =>
          selectedCategory == 'all' ||
              msg.category.toLowerCase() == selectedCategory.toLowerCase(),
        )
            .toList() ??
            [];

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
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
                constraints: const BoxConstraints(
                  maxWidth: 1250,
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
                  itemCount: messages.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: columns == 1 ? 350 : 365,
                  ),
                  itemBuilder: (context, index) {
                    return _buildMessageCard(messages[index]);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // MESSAGE CARD
  // ==========================================================

  Widget _buildMessageCard(Message msg) {
    final colors = _categoryColors(msg.category);
    final icon = _categoryIcon(msg.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMessage(msg),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: msg.isRead ? Colors.white : const Color(0xFFFCF9FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: msg.isRead
                  ? purple.withOpacity(0.07)
                  : purple.withOpacity(0.20),
              width: msg.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageCardHeader(msg, colors, icon),
              Expanded(
                child: _buildMessageCardBody(msg, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE CARD HEADER
  // ==========================================================

  Widget _buildMessageCardHeader(
      Message msg,
      List<Color> colors,
      IconData icon,
      ) {
    return Container(
      height: 112,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // DECORATIVE CIRCLES
          Positioned(
            right: -30,
            top: -45,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -60,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // ICON
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: purple,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _categoryLabel(msg.category),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (msg.isImportant) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'IMPORTANT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        msg.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.2,
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
    );
  }

  // ==========================================================
  // MESSAGE CARD BODY
  // ==========================================================

  Widget _buildMessageCardBody(
      Message msg,
      List<Color> colors,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AUTHOR
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: purple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!msg.isRead)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: purple,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // CONTENT PREVIEW
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: purple.withOpacity(0.06),
              ),
            ),
            child: Text(
              msg.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // DATE + READ MORE
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _formatDate(msg.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openMessage(msg),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                ),
                label: const Text('Read'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                  side: BorderSide(
                    color: purple.withOpacity(0.30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPEN MESSAGE DIALOG
  // ==========================================================

  Future<void> _openMessage(Message msg) async {
    if (!msg.isRead) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(msg.id)
            .update({
          'isRead': true,
        });
      } catch (_) {}
    }

    if (!mounted) return;

    final colors = _categoryColors(msg.category);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DIALOG HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _categoryIcon(msg.category),
                            color: purple,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryLabel(msg.category),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                msg.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DIALOG CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: purple.withOpacity(0.10),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: purple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.author,
                                    style: const TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(msg.timestamp),
                                    style: const TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SelectableText(
                            msg.content,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // EMPTY & ERROR STATES
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading messages: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}