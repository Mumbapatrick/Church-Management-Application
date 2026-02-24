import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto; // optional profile image URL
  final String location; // user location (optional field in UI)
  final String role; // user role (e.g., "member", "admin")

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
    required this.location,
    required this.role,
  });

  //  Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'location': location,
      'role': role,
    };
  }

  //  Convert from Firestore map
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: map['id'] ?? id,
      name: (map['name'] ?? '').toString().isNotEmpty ? map['name'] : 'User',
      email: (map['email'] ?? '').toString().isNotEmpty ? map['email'] : 'Unknown',
      phone: (map['phone'] ?? '').toString().isNotEmpty ? map['phone'] : 'Unknown',
      profilePhoto: map['profilePhoto'],
      location: map['location'] ?? '',
      role: map['role'] ?? 'member',
    );
  }

  //  Convert from Firebase Auth user
  factory User.fromFirebase(fbAuth.User fbUser, {String? location, String? role}) {
    final name = (fbUser.displayName?.trim().isNotEmpty ?? false)
        ? fbUser.displayName!
        : "User";

    final email = (fbUser.email?.trim().isNotEmpty ?? false)
        ? fbUser.email!
        : "Unknown";

    final phone = (fbUser.phoneNumber?.trim().isNotEmpty ?? false)
        ? fbUser.phoneNumber!
        : "Unknown";

    return User(
      id: fbUser.uid,
      name: name,
      email: email,
      phone: phone,
      profilePhoto: fbUser.photoURL,
      location: location ?? "",
      role: role ?? "member",
    );
  }
}

