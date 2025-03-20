class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String userType; // regular, sheikh, or admin
  final String phoneNumber;
  final DateTime? birthDate;
  final String profilePicture;
  final String bio;
  final bool isVerified;
  final DateTime createdAt;
  final List<int>? followerIds;
  final List<int>? followingIds;
  final SheikhProfile? sheikhProfile;
  // Add new fields
  final String firstName;
  final String lastName;
  final DateTime? dateJoined;
  final DateTime? lastLogin;
  final String gender; // Add gender field

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.userType = 'regular',
    this.phoneNumber = '',
    this.birthDate,
    this.profilePicture = '',
    this.bio = '',
    this.isVerified = false,
    required this.createdAt,
    this.followerIds,
    this.followingIds,
    this.sheikhProfile,
    // Add new fields to constructor
    this.firstName = '',
    this.lastName = '',
    this.dateJoined,
    this.lastLogin,
    this.gender = '', // Add gender field with default value
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'] ??
          "${json['first_name'] ?? ''} ${json['last_name'] ?? ''}".trim(),
      email: json['email'],
      userType: json['user_type'] ?? 'regular',
      phoneNumber: json['phone_number'] ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      profilePicture: json['profile_picture'] ?? '',
      bio: json['bio'] ?? '',
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      followerIds:
          json['followers'] != null ? List<int>.from(json['followers']) : [],
      followingIds:
          json['following'] != null ? List<int>.from(json['following']) : [],
      sheikhProfile: json['sheikh_profile'] != null
          ? SheikhProfile.fromJson(json['sheikh_profile'])
          : null,
      // Parse new fields
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      gender: json['gender'] ?? '', // Parse gender field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'user_type': userType,
      'phone_number': phoneNumber,
      'birth_date': birthDate?.toIso8601String(),
      'profile_picture': profilePicture,
      'bio': bio,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'followers': followerIds,
      'following': followingIds,
      // Include new fields
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'gender': gender, // Include gender in JSON output
    };
  }
}

class SheikhProfile {
  final int id;
  final int userId;
  final String certification;
  final String mosque;
  final String specialization;
  final Map<String, dynamic> teachingSchedule;
  final double rating;

  SheikhProfile({
    required this.id,
    required this.userId,
    required this.certification,
    required this.mosque,
    required this.specialization,
    required this.teachingSchedule,
    this.rating = 0.0,
  });

  factory SheikhProfile.fromJson(Map<String, dynamic> json) {
    return SheikhProfile(
      id: json['id'],
      userId: json['user'],
      certification: json['certification'] ?? '',
      mosque: json['mosque'] ?? '',
      specialization: json['specialization'] ?? '',
      teachingSchedule: json['teaching_schedule'] ?? {},
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'certification': certification,
      'mosque': mosque,
      'specialization': specialization,
      'teaching_schedule': teachingSchedule,
      'rating': rating,
    };
  }
}
