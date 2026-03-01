import 'dart:convert';

class UserProfile {
  String name;
  String email;
  String phone;
  String avatarEmoji;
  int avatarColorIndex;
  // Diubah ke imagePath agar sesuai dengan pemanggilan di FinanceProvider
  String? imagePath;
  // Cover banner (16:9) di belakang avatar pada profile card
  String? coverImagePath;
  DateTime joinDate;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarEmoji,
    required this.joinDate,
    this.avatarColorIndex = 0,
    this.imagePath,
    this.coverImagePath,
  });

  // Method copyWith WAJIB ada untuk mengatasi error "method 'copyWith' isn't defined"
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarEmoji,
    int? avatarColorIndex,
    String? imagePath,
    String? coverImagePath,
    DateTime? joinDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      imagePath: imagePath ?? this.imagePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'avatarEmoji': avatarEmoji,
        'avatarColorIndex': avatarColorIndex,
        'imagePath': imagePath,
        'coverImagePath': coverImagePath,
        'joinDate': joinDate.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        avatarEmoji: map['avatarEmoji'] ?? '👤',
        avatarColorIndex: map['avatarColorIndex'] ?? 0,
        imagePath: map['imagePath'],
        coverImagePath: map['coverImagePath'],
        joinDate: map['joinDate'] != null
            ? DateTime.parse(map['joinDate'])
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  static UserProfile get defaultProfile => UserProfile(
        name: '',
        email: '',
        phone: '',
        avatarEmoji: '👤',
        avatarColorIndex: 0,
        joinDate: DateTime.now(),
      );
}
