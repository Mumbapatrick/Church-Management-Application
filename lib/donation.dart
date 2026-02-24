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

// Custom formatter for MM/YY
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

  final donationTypes = [
    {'id': 'tithe', 'label': 'Tithes', 'description': '10% of your income to God'},
    {'id': 'offering', 'label': 'Offerings', 'description': 'Freewill offerings and gifts'},
    {'id': 'special', 'label': 'Special Projects', 'description': 'Building fund & initiatives'},
    {'id': 'missions', 'label': 'Missions', 'description': 'Support missionary work worldwide'},
  ];

  final quickAmounts = [10, 25, 50, 100, 250, 500];

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
      // Save donation to Firestore
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
    if (isSuccess) {
      return Scaffold(
        body: Center(
          child: Text(
            "Donation Successful!\nAmount: \$${amountController.text}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Donations & Tithes")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: quickAmounts.map((val) {
                  bool selected = amountController.text == val.toString();
                  return ChoiceChip(
                    label: Text("\$$val"),
                    selected: selected,
                    selectedColor: Colors.purple,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                    onSelected: (_) {
                      if (mounted) setState(() {
                        amountController.text = val.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Enter Amount",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter amount";
                  if (double.tryParse(value) == null) return "Enter valid number";
                  if (double.parse(value) < 1) return "Minimum donation is 1";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: paymentMethod,
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
              if (paymentMethod == 'mpesa')
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: "M-Pesa Phone (07XXXXXXXX or 01XXXXXXXX)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Enter phone number";
                    if (!RegExp(r'^(07|01)\d{8}$').hasMatch(value)) return "Invalid M-Pesa number";
                    return null;
                  },
                ),
              if (paymentMethod == 'card') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Card Number",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Enter card number";
                    if (value.length != 16) return "Card must be 16 digits";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cardExpiryController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ExpiryDateFormatter()],
                        decoration: const InputDecoration(
                          labelText: "MM/YY",
                          hintText: "MM/YY",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter expiry date";
                          if (!validateExpiry(value)) return "Card expired or invalid";
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
                        decoration: const InputDecoration(
                          labelText: "CVV",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter CVV";
                          if (value.length != 3) return "CVV must be 3 digits";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : handleDonate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.purple,
                  ),
                  child: isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Donate \$${amountController.text.isEmpty ? '0' : amountController.text}"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

