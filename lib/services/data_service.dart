// lib/services/data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';

class DataService {
  static final DataService _i = DataService._();
  factory DataService() => _i;
  DataService._();

  final _db = FirebaseFirestore.instance;

  // ── Children ───────────────────────────────────────────────────────────────
  Stream<List<ChildProfile>> watchChildren(String parentId) => _db
      .collection('children')
      .where('parentId', isEqualTo: parentId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ChildProfile.fromMap(d.data(), d.id))
          .toList());

  Future<void> addChild(ChildProfile c) =>
      _db.collection('children').add(c.toMap());

  // ── Red Zones ──────────────────────────────────────────────────────────────
  Stream<List<RedZone>> watchRedZones() => _db
      .collection('red_zones')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => RedZone.fromMap(d.data(), d.id)).toList());

  Future<void> reportRedZone({
    required String uid,
    required LatLng pos,
    required String reason,
  }) async {
    final all = await _db.collection('red_zones').get();
    for (final doc in all.docs) {
      final d = doc.data();
      final dist = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
      );
      if (dist < 150) {
        final count = ((d['reportCount'] ?? 1) as int) + 1;
        await doc.reference.update({
          'reportCount': count,
          'severity': count >= 10 ? 'high' : count >= 5 ? 'medium' : 'low',
          'reportedBy': FieldValue.arrayUnion([uid]),
          'updatedAt': Timestamp.now(),
        });
        return;
      }
    }
    await _db.collection('red_zones').add({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'radiusM': 200.0,
      'reason': reason,
      'reportCount': 1,
      'reportedBy': [uid],
      'severity': 'low',
      'createdAt': Timestamp.now(),
    });
  }

  // ── SOS ───────────────────────────────────────────────────────────────────
  Stream<List<SosEvent>> watchActiveSos(String parentId) => _db
      .collection('sos_events')
      .where('parentId', isEqualTo: parentId)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => SosEvent.fromMap(d.data(), d.id)).toList());

  Future<void> triggerSos(SosEvent e) =>
      _db.collection('sos_events').add(e.toMap());

  Future<void> respondSos(String sosId) =>
      _db.collection('sos_events').doc(sosId).update({
        'parentResponded': true,
        'status': 'resolved',
        'respondedAt': Timestamp.now(),
      });

  // ── Alerts ─────────────────────────────────────────────────────────────────
  Stream<List<AppAlert>> watchAlerts(String parentId) => _db
      .collection('alerts')
      .where('parentId', isEqualTo: parentId)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => AppAlert.fromMap(d.data(), d.id)).toList());

  Future<void> markAlertRead(String id) =>
      _db.collection('alerts').doc(id).update({'isRead': true});

  // ── Community ──────────────────────────────────────────────────────────────
  Stream<List<CommunityPost>> watchPosts() => _db
      .collection('community_posts')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map((s) => s.docs
          .map((d) => CommunityPost.fromMap(d.data(), d.id))
          .toList());

  Future<void> createPost(CommunityPost p, {LatLng? pos}) async {
    final map = p.toMap();
    if (pos != null) {
      map['lat'] = pos.latitude;
      map['lng'] = pos.longitude;
    }
    await _db.collection('community_posts').add(map);
    // auto-increment red-zone for hazard posts
    if ((p.category == 'hazard' || p.category == 'suspicious') && pos != null) {
      await reportRedZone(uid: p.authorId, pos: pos, reason: p.content);
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    final ref = _db.collection('community_posts').doc(postId);
    final snap = await ref.get();
    final liked = List<String>.from(snap.data()?['likedBy'] ?? []);
    if (liked.contains(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }
}