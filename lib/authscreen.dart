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

class AuthScreen extends StatefulWidget {
  final Function(User) onLogin;
  const AuthScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

  final _auth = fbAuth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupLocationController = TextEditingController();
  final _signupPasswordController = TextEditingController();

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
    super.dispose();
  }

  // ---------- TOAST HELPERS ----------
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

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        location.isEmpty ||
        password.isEmpty) {
      _showError("Please fill all fields");
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
      final clientId = EnvConfig.webClientId;
      if (clientId == null || clientId.isEmpty) {
        _showError("Missing Google WEB_CLIENT_ID. Please configure it first.");
        return;
      }

      if (kIsWeb) {
        final googleProvider = fbAuth.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        await _loadUserFromFirebase(userCredential.user!.uid, createIfMissing: true);
        await _navigateToDashboard(userCredential.user!);
        _showSuccess("Google login successful!");
      } else {
        final googleSignIn = GoogleSignIn(clientId: clientId);
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          _showError("Google sign-in canceled");
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = fbAuth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        await _loadUserFromFirebase(userCredential.user!.uid, createIfMissing: true);
        await _navigateToDashboard(userCredential.user!);
        _showSuccess("Google login successful!");
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
          title: const Text("Enter Phone Number"),
          content: TextField(
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: "+254700000000"),
            onChanged: (v) => phone = v,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (phone.isEmpty || !phone.startsWith('+')) {
                  _showError("Please enter a valid phone number");
                } else {
                  Navigator.pop(ctx);
                  _startPhoneVerification(phone);
                }
              },
              child: const Text("Next"),
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
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Word & Prayer for All Nations",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [Tab(text: "Login"), Tab(text: "Sign Up")],
                    ),
                    SizedBox(
                      height: 500,
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
    );
  }

  // ---------- LOGIN TAB ----------
  Widget _buildLoginTab() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: "Password"),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resetPassword,
            child: const Text("Forgot Password?"),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.purple),
          child: Text(isLoading ? "Logging in..." : "Login"),
        ),
        const SizedBox(height: 16),
        const Text("Or continue with:"),
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
    );
  }

  // ---------- SIGNUP TAB ----------
  Widget _buildSignupTab() {
    return Column(
      children: [
        TextField(
          controller: _signupNameController,
          decoration: const InputDecoration(labelText: "Full Name"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupEmailController,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupPhoneController,
          decoration: const InputDecoration(labelText: "Phone Number"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupLocationController,
          decoration: const InputDecoration(labelText: "Location"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupPasswordController,
          decoration: const InputDecoration(labelText: "Password"),
          obscureText: true,
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: isLoading ? null : _handleSignup,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.purple),
          child: Text(isLoading ? "Creating..." : "Sign Up"),
        ),
        const SizedBox(height: 12),
        const Text("Or sign up with:"),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(FontAwesomeIcons.google, Colors.red, _handleGoogleLogin),
            const SizedBox(width: 16),
            _socialButton(FontAwesomeIcons.phone, Colors.green, _goToPhoneInput),
          ],
        ),
      ],
    );
  }

  // ---------- SOCIAL BUTTON ----------
  Widget _socialButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Center(child: FaIcon(icon, color: color, size: 24)),
      ),
    );
  }
}

