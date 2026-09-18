import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/user.dart';

class DonationsScreen extends StatefulWidget {
  final User user;
  final VoidCallback onBack;

  const DonationsScreen({
    super.key,
    required this.user,
    required this.onBack,
  });

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) formatted += '/';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _DonationsScreenState extends State<DonationsScreen> {
  final _formKey = GlobalKey<FormState>();

  String donationType = 'tithe';
  String paymentMethod = 'mpesa';
  bool isProcessing = false;
  bool isSuccess = false;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardCvvController = TextEditingController();

  static const Color purplePrimary = Color(0xFF6A0DAD);
  static const Color purpleLight = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF4C087A);
  static const Color inputBg = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  final donationTypes = [
    {'id': 'tithe', 'label': 'Tithes', 'description': '10% of your income to God'},
    {'id': 'offering', 'label': 'Offerings', 'description': 'Freewill offerings and gifts'},
    {'id': 'special', 'label': 'Special Projects', 'description': 'Building fund & initiatives'},
    {'id': 'missions', 'label': 'Missions', 'description': 'Support missionary work worldwide'},
  ];

  final quickAmounts = [100, 250, 500, 1000, 2500, 5000];

  @override
  void initState() {
    super.initState();
    amountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    phoneController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvvController.dispose();
    super.dispose();
  }

  Future<void> handleDonate() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => isProcessing = true);

    try {
      await FirebaseFirestore.instance.collection('donations').add({
        'userId': widget.user.id,
        'userName': widget.user.name,
        'amount': double.parse(amountController.text),
        'donationType': donationType,
        'paymentMethod': paymentMethod,
        'phone': paymentMethod == 'mpesa' ? phoneController.text : null,
        'cardNumber': paymentMethod == 'card' ? cardNumberController.text : null,
        'cardExpiry': paymentMethod == 'card' ? cardExpiryController.text : null,
        'cardCvv': paymentMethod == 'card' ? cardCvvController.text : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        isProcessing = false;
        isSuccess = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          isSuccess = false;
          _formKey.currentState?.reset();
          amountController.clear();
          phoneController.clear();
          cardNumberController.clear();
          cardExpiryController.clear();
          cardCvvController.clear();
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save donation: $e")),
      );
    }
  }

  bool validateExpiry(String value) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) return false;

    final parts = value.split('/');
    int month = int.parse(parts[0]);
    int year = int.parse(parts[1]) + 2000;

    final now = DateTime.now();

    if (year < now.year) return false;
    if (year == now.year && month < now.month) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final double currentAmount = double.tryParse(amountController.text.trim()) ?? 0;

    if (isSuccess) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [purpleDark, purplePrimary, purpleLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: purplePrimary, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          "Donation Successful!",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Amount: KES ${currentAmount.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 16, color: textGrey),
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
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [purpleDark, purplePrimary, purpleLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("Select Giving Type", isRequired: true),
                                const SizedBox(height: 10),
                                _buildGivingTypesGrid(),
                                const SizedBox(height: 18),

                                _buildSectionLabel("Quick Amount (KES)"),
                                const SizedBox(height: 10),
                                _buildQuickAmountGrid(currentAmount),
                                const SizedBox(height: 18),

                                _buildSectionLabel("Enter Amount (KES)", isRequired: true),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                                  decoration: _buildInputDecoration(
                                    hintText: "e.g. 1000",
                                    icon: Icons.payments_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return "Please enter amount";
                                    if (double.tryParse(value) == null) return "Enter a valid number";
                                    if (double.parse(value) < 1) return "Minimum donation is KES 1";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                _buildSectionLabel("Payment Method", isRequired: true),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: paymentMethod,
                                  menuMaxHeight: 200,
                                  itemHeight: 48,
                                  style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500),
                                  decoration: _buildInputDecoration(
                                    hintText: "Select Payment Method",
                                    icon: Icons.account_balance_wallet_outlined,
                                    isDense: true,
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey, size: 20),
                                  items: const [
                                    DropdownMenuItem(value: 'mpesa', child: Text("M-Pesa")),
                                    DropdownMenuItem(value: 'card', child: Text("Card")),
                                    DropdownMenuItem(value: 'bank', child: Text("Bank")),
                                  ],
                                  onChanged: (val) {
                                    if (mounted) setState(() => paymentMethod = val!);
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (paymentMethod == 'mpesa') ...[
                                  _buildSectionLabel("M-Pesa Phone Number", isRequired: true),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                                    decoration: _buildInputDecoration(
                                      hintText: "07XXXXXXXX / 01XXXXXXXX",
                                      icon: Icons.smartphone_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Please enter phone number";
                                      if (!RegExp(r'^(07|01)\d{8}$').hasMatch(value)) return "Invalid M-Pesa number";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                if (paymentMethod == 'card') ...[
                                  _buildSectionLabel("Card Details", isRequired: true),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: cardNumberController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(16),
                                    ],
                                    style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                                    decoration: _buildInputDecoration(
                                      hintText: "1234 5678 9012 3456",
                                      icon: Icons.credit_card_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Enter card number";
                                      if (value.length != 16) return "Card must be 16 digits";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: cardExpiryController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [ExpiryDateFormatter()],
                                          style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                                          decoration: _buildInputDecoration(
                                            hintText: "MM/YY",
                                            icon: Icons.calendar_today_outlined,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return "Enter expiry";
                                            if (!validateExpiry(value)) return "Expired / Invalid";
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: cardCvvController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                          style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                                          decoration: _buildInputDecoration(
                                            hintText: "CVV",
                                            icon: Icons.lock_outline,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return "Enter CVV";
                                            if (value.length != 3) return "Must be 3 digits";
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isProcessing ? null : handleDonate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: purplePrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isProcessing
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.favorite_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Donate KES ${currentAmount == currentAmount.roundToDouble() ? currentAmount.toInt() : currentAmount.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: purplePrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Donations & Tithes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Give cheerfully and support kingdom work",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGivingTypesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: donationTypes.map((type) {
            final isSelected = donationType == type['id'];

            return GestureDetector(
              onTap: () => setState(() => donationType = type['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? purplePrimary : inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? purplePrimary : Colors.grey.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type['description'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: isSelected ? Colors.white.withOpacity(0.85) : textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickAmountGrid(double currentAmount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickAmounts.map((amt) {
            final isSelected = currentAmount == amt.toDouble();

            return GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() {
                    amountController.text = amt.toString();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: width,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? purplePrimary.withOpacity(0.1) : inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? purplePrimary : Colors.grey.withOpacity(0.15),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    "KES $amt",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? purplePrimary : textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: " *",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    bool isDense = false,
  }) {
    return InputDecoration(
      isDense: isDense,
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: textGrey.withOpacity(0.6),
      ),
      prefixIcon: Icon(icon, color: purplePrimary, size: 18),
      filled: true,
      fillColor: inputBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: isDense ? 10 : 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: purplePrimary, width: 1.5),
      ),
    );
  }
}