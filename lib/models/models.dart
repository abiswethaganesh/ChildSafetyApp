// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

// ────────────────────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final LatLng? lastLocation;
  final List<String> childIds;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.lastLocation,
    this.childIds = const [],
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> m, String uid) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        photoUrl: m['photoUrl'],
        lastLocation: m['lat'] != null
            ? LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble())
            : null,
        childIds: List<String>.from(m['childIds'] ?? []),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'childIds': childIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ────────────────────────────────────────────────────────────────────────────
class ChildProfile {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String? photoUrl;
  final String? deviceId;
  final LatLng? location;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool inRedZone;
  final String status; // 'safe' | 'warning' | 'danger'
  // Trusted places
  final List<TrustedPlace> trustedPlaces;

  ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.photoUrl,
    this.deviceId,
    this.location,
    this.isOnline = false,
    this.lastSeen,
    this.inRedZone = false,
    this.status = 'safe',
    this.trustedPlaces = const [],
  });

  factory ChildProfile.fromMap(Map<String, dynamic> m, String id) =>
      ChildProfile(
        id: id,
        parentId: m['parentId'] ?? '',
        name: m['name'] ?? '',
        age: (m['age'] ?? 0) as int,
        photoUrl: m['photoUrl'],
        deviceId: m['deviceId'],
        location: m['lat'] != null
            ? LatLng(
                (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble())
            : null,
        isOnline: m['isOnline'] ?? false,
        lastSeen: (m['lastSeen'] as Timestamp?)?.toDate(),
        inRedZone: m['inRedZone'] ?? false,
        status: m['status'] ?? 'safe',
        trustedPlaces: (m['trustedPlaces'] as List<dynamic>? ?? [])
            .map((e) => TrustedPlace.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'parentId': parentId,
        'name': name,
        'age': age,
        'photoUrl': photoUrl,
        'deviceId': deviceId,
        'isOnline': isOnline,
        'inRedZone': inRedZone,
        'status': status,
        'trustedPlaces': trustedPlaces.map((e) => e.toMap()).toList(),
      };
}

// ────────────────────────────────────────────────────────────────────────────
class TrustedPlace {
  final String label; // 'Home', "Grandma's", "Aunt Priya's"
  final LatLng location;
  final double radiusM;

  TrustedPlace({required this.label, required this.location, this.radiusM = 100});

  factory TrustedPlace.fromMap(Map<String, dynamic> m) => TrustedPlace(
        label: m['label'] ?? '',
        location: LatLng(
            (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
        radiusM: (m['radiusM'] ?? 100).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'lat': location.latitude,
        'lng': location.longitude,
        'radiusM': radiusM,
      };
}

// ────────────────────────────────────────────────────────────────────────────
class RedZone {
  final String id;
  final LatLng center;
  final double radiusM;
  final String reason;
  final int reportCount;
  final String severity; // 'low' | 'medium' | 'high'
  final DateTime createdAt;

  RedZone({
    required this.id,
    required this.center,
    required this.radiusM,
    required this.reason,
    required this.reportCount,
    required this.severity,
    required this.createdAt,
  });

  factory RedZone.fromMap(Map<String, dynamic> m, String id) => RedZone(
        id: id,
        center: LatLng(
            (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
        radiusM: (m['radiusM'] ?? 200).toDouble(),
        reason: m['reason'] ?? '',
        reportCount: (m['reportCount'] ?? 1) as int,
        severity: m['severity'] ?? 'low',
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ────────────────────────────────────────────────────────────────────────────
class SosEvent {
  final String id;
  final String childId;
  final String parentId;
  final String type; // 'fall' | 'kidnap' | 'manual'
  final LatLng location;
  final DateTime triggeredAt;
  final String status; // 'active' | 'resolved' | 'escalated'
  final bool parentResponded;

  SosEvent({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.type,
    required this.location,
    required this.triggeredAt,
    this.status = 'active',
    this.parentResponded = false,
  });

  factory SosEvent.fromMap(Map<String, dynamic> m, String id) => SosEvent(
        id: id,
        childId: m['childId'] ?? '',
        parentId: m['parentId'] ?? '',
        type: m['type'] ?? 'manual',
        location: LatLng(
            (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
        triggeredAt:
            (m['triggeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: m['status'] ?? 'active',
        parentResponded: m['parentResponded'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'parentId': parentId,
        'type': type,
        'lat': location.latitude,
        'lng': location.longitude,
        'triggeredAt': Timestamp.fromDate(triggeredAt),
        'status': status,
        'parentResponded': parentResponded,
      };
}

// ────────────────────────────────────────────────────────────────────────────
class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String category; // 'missing_child'|'hazard'|'suspicious'|'child_alone'|'general'
  final LatLng? location;
  final String? locationLabel;
  final List<String> imageUrls;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;
  final bool isVerified;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.category,
    this.location,
    this.locationLabel,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.likedBy = const [],
    this.commentsCount = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> m, String id) =>
      CommunityPost(
        id: id,
        authorId: m['authorId'] ?? '',
        authorName: m['authorName'] ?? '',
        authorPhotoUrl: m['authorPhotoUrl'],
        content: m['content'] ?? '',
        category: m['category'] ?? 'general',
        location: m['lat'] != null
            ? LatLng((m['lat'] as num).toDouble(),
                (m['lng'] as num).toDouble())
            : null,
        locationLabel: m['locationLabel'],
        imageUrls: List<String>.from(m['imageUrls'] ?? []),
        likesCount: (m['likesCount'] ?? 0) as int,
        likedBy: List<String>.from(m['likedBy'] ?? []),
        commentsCount: (m['commentsCount'] ?? 0) as int,
        isVerified: m['isVerified'] ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'category': category,
        'locationLabel': locationLabel,
        'imageUrls': imageUrls,
        'likesCount': likesCount,
        'likedBy': likedBy,
        'commentsCount': commentsCount,
        'isVerified': isVerified,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ────────────────────────────────────────────────────────────────────────────
class AppAlert {
  final String id;
  final String parentId;
  final String childId;
  final String type;
  final String message;
  final String severity; // 'info' | 'warning' | 'critical'
  final bool isRead;
  final DateTime createdAt;

  AppAlert({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.type,
    required this.message,
    required this.severity,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppAlert.fromMap(Map<String, dynamic> m, String id) => AppAlert(
        id: id,
        parentId: m['parentId'] ?? '',
        childId: m['childId'] ?? '',
        type: m['type'] ?? '',
        message: m['message'] ?? '',
        severity: m['severity'] ?? 'info',
        isRead: m['isRead'] ?? false,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}