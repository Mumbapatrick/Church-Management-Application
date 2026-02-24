import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dashboard.dart';
import 'model/user.dart'; // your User model

class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  final String phone; // passed from previous screen

  const OtpVerifyScreen({super.key, required this.verificationId, required this.phone});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  // 🔹 Helper toast functions
  void _showError(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.redAccent,
    textColor: Colors.white,
  );

  void _showSuccess(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.green,
    textColor: Colors.white,
  );

  // 🔹 Verify OTP
  Future<void> _verifyCode() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) {
      _showError("Please enter the OTP code");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = fbAuth.PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user;

      if (fbUser == null) {
        _showError("Verification failed. Try again.");
        return;
      }

      // ✅ Create Firestore record if not exists
      final docRef = _firestore.collection("users").doc(fbUser.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        final newUser = User(
          id: fbUser.uid,
          name: fbUser.displayName ?? "Phone User",
          email: fbUser.email ?? "",
          phone: fbUser.phoneNumber ?? widget.phone,
          location: "",
          role: "member",
        );

        await docRef.set(newUser.toMap());
      }

      _showSuccess("Phone verification successful!");

      // ✅ Navigate to Dashboard
      final appUser = User(
        id: fbUser.uid,
        name: fbUser.displayName ?? "Phone User",
        email: fbUser.email ?? "",
        phone: fbUser.phoneNumber ?? widget.phone,
        location: "",
        role: "member",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(user: appUser)),
      );
    } catch (e) {
      _showError("Invalid or expired OTP. Try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Phone Verification",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Enter the 6-digit OTP sent to your phone",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "OTP Code",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


