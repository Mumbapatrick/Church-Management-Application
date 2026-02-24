class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String role;
  final String location;
  final String dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String occupation;
  final String addedBy; //  New field
  final String? approvedBy;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.role,
    this.location = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.addedBy = '', // default empty
    this.approvedBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'department': department,
    'role': role,
    'location': location,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'maritalStatus': maritalStatus,
    'occupation': occupation,
    'addedBy': addedBy, // include in map
  };

  factory Member.fromMap(String id, Map<String, dynamic> map) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] ?? 'member',
      location: map['location'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      maritalStatus: map['maritalStatus'] ?? '',
      occupation: map['occupation'] ?? '',
      addedBy: map['addedBy'] ?? '',
      approvedBy: map['approvedBy'],
    );
  }
}
