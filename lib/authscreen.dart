import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'otp.dart';
import 'dashboard.dart';
import 'model/user.dart';
import 'env_config.dart';

// ============================================================
// COLORS — MATCHED TO APP THEME
// ============================================================

const Color purple = Color(0xFF6A0DAD);
const Color purpleLight = Color(0xFF8B5CF6);
const Color purpleDark = Color(0xFF4C087A);
const Color gold = Color(0xFFFFD700);

class AuthScreen extends StatefulWidget {
  final Function(User) onLogin;
  const AuthScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

  // Password visibility states
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  final _auth = fbAuth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupLocationController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupLocationController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  // ---------- TOAST HELPERS ----------
  void _showError(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.red.shade700,
    textColor: Colors.white,
  );

  void _showSuccess(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: purple,
    textColor: Colors.white,
  );

  // ---------- LOGIN ----------
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError("Enter a valid email address");
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final fbUser = credential.user;
      if (fbUser == null) {
        _showError("Authentication failed. Please try again.");
        return;
      }

      final success =
      await _navigateToDashboard(fbUser, suppressSuccessToast: true);

      if (success) {
        _showSuccess("Login successful!");
      } else {
        await _auth.signOut();
        _showError("Access denied. No valid record found for this account.");
      }
    } on fbAuth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _showError("No user found for that email.");
          break;
        case 'wrong-password':
          _showError("Incorrect password.");
          break;
        case 'invalid-email':
          _showError("Invalid email format.");
          break;
        default:
          _showError(e.message ?? "Login failed.");
      }
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- SIGNUP ----------
  Future<void> _handleSignup() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final location = _signupLocationController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        location.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final newUser = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        location: location,
        role: "user",
      );

      await _firestore.collection("users").doc(newUser.id).set(newUser.toMap());
      widget.onLogin(newUser);

      _showSuccess("Signup successful!");
      await _navigateToDashboard(credential.user!);
    } on fbAuth.FirebaseAuthException catch (e) {
      _showError(e.message ?? "Signup failed");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- RESET PASSWORD ----------
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      _showError("Enter a valid email address");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccess("Password reset email sent!");
    } on fbAuth.FirebaseAuthException catch (e) {
      _showError(e.message ?? "Failed to send reset email");
    }
  }

  // ---------- GOOGLE LOGIN ----------
  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      if (kIsWeb) {
        final googleProvider = fbAuth.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _loadUserFromFirebase(userCredential.user!.uid, createIfMissing: true);
          await _navigateToDashboard(userCredential.user!);
          _showSuccess("Google login successful!");
        }
      } else {
        await GoogleSignIn.instance.initialize();
        final googleUser = await GoogleSignIn.instance.authenticate();

        final googleAuth = await googleUser.authentication;
        final credential = fbAuth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _loadUserFromFirebase(userCredential.user!.uid, createIfMissing: true);
          await _navigateToDashboard(userCredential.user!);
          _showSuccess("Google login successful!");
        }
      }
    } catch (e) {
      _showError("Google login failed: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- PHONE LOGIN ----------
  void _goToPhoneInput() {
    showDialog(
      context: context,
      builder: (ctx) {
        String phone = "";
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Enter Phone Number", style: TextStyle(fontWeight: FontWeight.w800)),
          content: TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "+254700000000",
              filled: true,
              fillColor: const Color(0xFFF4ECFA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => phone = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (phone.isEmpty || !phone.startsWith('+')) {
                  _showError("Please enter a valid phone number");
                } else {
                  Navigator.pop(ctx);
                  _startPhoneVerification(phone);
                }
              },
              child: const Text("Next", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _startPhoneVerification(String phone) async {
    setState(() => isLoading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        final userCred = await _auth.signInWithCredential(credential);
        await _loadUserFromFirebase(userCred.user!.uid, createIfMissing: true);
        await _navigateToDashboard(userCred.user!);
        _showSuccess("Phone login successful!");
      },
      verificationFailed: (e) => _showError(e.message ?? "Verification failed"),
      codeSent: (verificationId, resendToken) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerifyScreen(verificationId: verificationId, phone: phone),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    if (mounted) setState(() => isLoading = false);
  }

  // ---------- LOAD USER ----------
  Future<void> _loadUserFromFirebase(String uid,
      {bool createIfMissing = false}) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) {
      widget.onLogin(User.fromMap(doc.data()!, uid));
    } else if (createIfMissing) {
      final fbUser = _auth.currentUser!;
      final user = User(
        id: fbUser.uid,
        name: fbUser.displayName ?? "New User",
        email: fbUser.email ?? "",
        phone: fbUser.phoneNumber ?? "",
        location: "",
        role: "user",
      );
      await _firestore.collection("users").doc(uid).set(user.toMap());
      widget.onLogin(user);
    } else {
      _showError("User data not found");
    }
  }

  // ---------- NAVIGATE TO DASHBOARD ----------
  Future<bool> _navigateToDashboard(fbAuth.User fbUser,
      {bool suppressSuccessToast = false}) async {
    if (!mounted) return false;

    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;

      final userDoc = await _firestore.collection("users").doc(fbUser.uid).get();
      if (userDoc.exists) {
        doc = userDoc;
      } else {
        final memberDoc =
        await _firestore.collection("members").doc(fbUser.uid).get();
        if (memberDoc.exists) doc = memberDoc;
      }

      if (doc == null || !doc.exists) {
        _showError("User record not found in either 'users' or 'members'.");
        return false;
      }

      final data = doc.data();
      if (data == null || !data.containsKey("role")) {
        _showError("Invalid user data. Please contact admin.");
        return false;
      }

      final user = User.fromMap(data, fbUser.uid);
      widget.onLogin(user);

      if (!suppressSuccessToast) _showSuccess("Welcome, ${user.name}!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(user: user)),
      );

      return true;
    } catch (e) {
      _showError("Error verifying user record: $e");
      return false;
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: purple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.church_rounded,
                          color: purple,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Word & Prayer for All Nations",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202124),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Sign in or create an account to continue",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4ECFA),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: purple,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: "Login"),
                            Tab(text: "Sign Up"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 480, // Increased height slightly to fit extra field
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildLoginTab(), _buildSignupTab()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- CUSTOM TEXT FIELD HELPER ----------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF9F6FC),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
    );
  }

  // ---------- LOGIN TAB ----------
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildTextField(controller: _emailController, label: "Email"),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isLoading ? "Logging in..." : "Login",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Or continue with",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(FontAwesomeIcons.google, Colors.red, _handleGoogleLogin),
              const SizedBox(width: 16),
              _socialButton(FontAwesomeIcons.phone, Colors.green, _goToPhoneInput),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- SIGNUP TAB ----------
  Widget _buildSignupTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildTextField(controller: _signupNameController, label: "Full Name"),
          const SizedBox(height: 10),
          _buildTextField(controller: _signupEmailController, label: "Email"),
          const SizedBox(height: 10),
          _buildTextField(controller: _signupPhoneController, label: "Phone Number"),
          const SizedBox(height: 10),
          _buildTextField(controller: _signupLocationController, label: "Location"),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _signupPasswordController,
            label: "Password",
            obscureText: _obscureSignupPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureSignupPassword = !_obscureSignupPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _signupConfirmPasswordController,
            label: "Confirm Password",
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: gold,
              foregroundColor: purpleDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isLoading ? "Creating..." : "Sign Up",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Or sign up with",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(FontAwesomeIcons.google, Colors.red, _handleGoogleLogin),
              const SizedBox(width: 16),
              _socialButton(FontAwesomeIcons.phone, Colors.green, _goToPhoneInput),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- SOCIAL BUTTON ----------
  Widget _socialButton(dynamic iconData, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Center(
          child: FaIcon(
            iconData,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}