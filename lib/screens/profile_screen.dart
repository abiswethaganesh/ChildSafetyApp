// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.teal, AppColors.mint]),
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.tealLight,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person,
                        color: AppColors.teal, size: 44) : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(user?.displayName ?? 'Guardian Parent',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(user?.email ?? '',
                style: const TextStyle(
                    color: AppColors.textMid, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded,
                    color: AppColors.teal, size: 15),
                SizedBox(width: 5),
                Text('Verified Google Account',
                    style: TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 32),

            // Settings tiles
            _Tile(Icons.child_care_rounded, 'Manage Children',
                AppColors.teal, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageChildrenScreen(
                    parentId: user?.uid ?? ''),
                ),
              );
            }),
            _Tile(Icons.watch_rounded, 'Paired Devices',
                AppColors.lavender, onTap: () {}),
            _Tile(Icons.place_rounded, 'Trusted Places',
                AppColors.amber, onTap: () {}),
            _Tile(Icons.notifications_rounded, 'Notifications',
                AppColors.mint, onTap: () {}),
            _Tile(Icons.privacy_tip_rounded, 'Privacy & Safety',
                AppColors.coral, onTap: () {}),
            _Tile(Icons.help_rounded, 'Help & Support',
                AppColors.textMid, onTap: () {}),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.coral),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.coral, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Guardian v1.0 · Made with ❤️ for child safety',
                style: TextStyle(
                    color: AppColors.textLight, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

// ── Manage Children Screen ────────────────────────────────────────────────────
class ManageChildrenScreen extends StatelessWidget {
  final String parentId;
  const ManageChildrenScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manage Children'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('children')
            .where('parentId', isEqualTo: parentId)
            .snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];

          return Column(children: [
            // Add child button at top
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context, parentId),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add a Child'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

            if (snap.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(
                  child: CircularProgressIndicator(color: AppColors.teal))),

            if (docs.isEmpty && snap.connectionState != ConnectionState.waiting)
              Expanded(child: _EmptyChildState(
                onAdd: () => _showAddEditDialog(context, parentId))),

            if (docs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _ChildCard(
                      docId: doc.id,
                      name: data['name'] ?? '',
                      age: data['age'] ?? 0,
                      gender: data['gender'] ?? 'Not specified',
                      school: data['school'] ?? '',
                      onEdit: () => _showAddEditDialog(
                        context, parentId, docId: doc.id, data: data),
                      onDelete: () => _confirmDelete(context, doc.id, data['name'] ?? ''),
                    );
                  },
                ),
              ),
          ]);
        },
      ),
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    String parentId, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final nameCtrl   = TextEditingController(text: data?['name'] ?? '');
    final ageCtrl    = TextEditingController(
        text: data?['age'] != null ? '${data!['age']}' : '');
    final schoolCtrl = TextEditingController(text: data?['school'] ?? '');
    String gender    = data?['gender'] ?? 'Not specified';
    final db         = FirebaseFirestore.instance;
    final isEdit     = docId != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(
            top: 20, left: 24, right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),

            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.tealLight, shape: BoxShape.circle),
                child: const Center(
                    child: Text('👶', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'Edit Child Profile' : 'Add Child Profile',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
            ]),
            const SizedBox(height: 20),

            // Name
            _FormLabel("Child's full name"),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textDark),
              decoration: _inputDeco('e.g. Riya Sharma',
                  icon: Icons.person_outline_rounded),
            ),
            const SizedBox(height: 14),

            // Age
            _FormLabel('Age'),
            const SizedBox(height: 6),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark),
              decoration: _inputDeco('e.g. 7',
                  icon: Icons.cake_outlined),
            ),
            const SizedBox(height: 14),

            // Gender
            _FormLabel('Gender'),
            const SizedBox(height: 8),
            Row(children: ['Girl', 'Boy', 'Not specified'].map((g) {
              final sel = gender == g;
              return GestureDetector(
                onTap: () => set(() => gender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.teal : AppColors.divider,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(g,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.textMid)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),

            // School
            _FormLabel('School name (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: schoolCtrl,
              style: const TextStyle(color: AppColors.textDark),
              decoration: _inputDeco('e.g. St. Mary\'s Primary School',
                  icon: Icons.school_outlined),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final age  = int.tryParse(ageCtrl.text.trim()) ?? 0;
                  if (name.isEmpty) return;

                  final payload = {
                    'parentId': parentId,
                    'name': name,
                    'age': age,
                    'gender': gender,
                    'school': schoolCtrl.text.trim(),
                    'status': 'safe',
                    'isOnline': false,
                    'inRedZone': false,
                    'trustedPlaces': [],
                    'updatedAt': Timestamp.now(),
                  };

                  if (isEdit) {
                    await db.collection('children').doc(docId).update(payload);
                  } else {
                    payload['createdAt'] = Timestamp.now();
                    await db.collection('children').add(payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Add Child',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove child?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        content: Text(
          'Are you sure you want to remove $name from your account?',
          style: const TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('children').doc(docId).delete();
    }
  }

  InputDecoration _inputDeco(String hint, {required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textMid, size: 20),
      filled: true,
      fillColor: AppColors.divider,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
    );
  }
}

// ── Child card on manage screen ───────────────────────────────────────────────
class _ChildCard extends StatelessWidget {
  final String docId, name, gender, school;
  final int age;
  final VoidCallback onEdit, onDelete;

  const _ChildCard({
    required this.docId, required this.name, required this.age,
    required this.gender, required this.school,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: const BoxDecoration(
              color: AppColors.tealLight, shape: BoxShape.circle),
          child: Center(
            child: Text(
              gender == 'Girl' ? '👧' : gender == 'Boy' ? '👦' : '👶',
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16,
                color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text('Age $age · $gender',
                style: const TextStyle(
                    color: AppColors.textMid, fontSize: 12)),
            if (school.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.school_rounded,
                    size: 12, color: AppColors.teal),
                const SizedBox(width: 4),
                Expanded(child: Text(school,
                    style: const TextStyle(
                        color: AppColors.teal, fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ],
        )),
        // Edit button
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_rounded,
                color: AppColors.teal, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Delete button
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.coral, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyChildState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyChildState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('👶', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('No children added yet',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        const Text(
          'Add your child\'s profile to start\ntracking and keeping them safe',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMid, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add First Child'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textMid));
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Tile(this.icon, this.label, this.color, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15,
            color: AppColors.textDark)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.textLight),
        onTap: onTap,
      ),
    );
  }
}