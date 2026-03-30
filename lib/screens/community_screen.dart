// lib/screens/community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _dataSvc = DataService();
  String _filter = 'all';

  User? get _user => FirebaseAuth.instance.currentUser;

  static const _categories = [
    {'id': 'all',           'emoji': '🌍', 'label': 'All'},
    {'id': 'missing_child', 'emoji': '🆘', 'label': 'Missing Child'},
    {'id': 'hazard',        'emoji': '⚠️',  'label': 'Hazard'},
    {'id': 'suspicious',   'emoji': '👁️',  'label': 'Suspicious'},
    {'id': 'child_alone',  'emoji': '👶',  'label': 'Child Alone'},
    {'id': 'general',      'emoji': '📢',  'label': 'General'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildPostBox(),
            _buildCategoryBar(),
            Expanded(child: _buildFeed()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Community Watch',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(
          'Stay informed · Keep kids safe · Verified parents only',
          style: const TextStyle(fontSize: 12, color: AppColors.textMid),
        ),
      ]),
    );
  }

  Widget _buildPostBox() {
    return GestureDetector(
      onTap: _showPostDialog,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Row(children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.tealLight,
            backgroundImage: _user?.photoURL != null
                ? NetworkImage(_user!.photoURL!)
                : null,
            child: _user?.photoURL == null
                ? const Icon(Icons.person, color: AppColors.teal, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Report something in your area… drunk men, no street lights, child alone?',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          ),
        ]),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categories.map((cat) {
          final sel = _filter == cat['id'];
          return GestureDetector(
            onTap: () => setState(() => _filter = cat['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.teal : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${cat['emoji']} ${cat['label']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.textMid,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<List<CommunityPost>>(
      stream: _dataSvc.watchPosts(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.teal));
        }
        var posts = snap.data ?? [];
        if (_filter != 'all') {
          posts = posts.where((p) => p.category == _filter).toList();
        }
        if (posts.isEmpty) return _buildEmpty();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: posts.length,
          itemBuilder: (_, i) => _PostCard(
            post: posts[i],
            currentUid: _user?.uid ?? '',
            onLike: () => _dataSvc.toggleLike(posts[i].id, _user?.uid ?? ''),
          ).animate().fadeIn(delay: (i * 50).ms),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🏘️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Nothing here yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Be the first to report something',
            style: TextStyle(color: AppColors.textMid)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showPostDialog,
          icon: const Icon(Icons.add),
          label: const Text('Post a report'),
        ),
      ]),
    );
  }

  void _showPostDialog() {
    if (_user == null) return;
    final contentCtrl = TextEditingController();
    String selCat = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.tealLight,
                  backgroundImage: _user?.photoURL != null
                      ? NetworkImage(_user!.photoURL!)
                      : null,
                  child: _user?.photoURL == null
                      ? const Icon(Icons.person, color: AppColors.teal, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_user?.displayName ?? 'Parent',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textDark)),
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: AppColors.mint, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Verified parent',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mint,
                            fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ]),
              const SizedBox(height: 16),

              // Category chips
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.skip(1).map((cat) {
                  final sel = selCat == cat['id'];
                  return GestureDetector(
                    onTap: () => set(() => selCat = cat['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.teal : AppColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.teal : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        '${cat['emoji']} ${cat['label']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppColors.textMid,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Text field
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: const TextStyle(
                    color: AppColors.textDark, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'What did you notice? e.g. "Drunk men near St. Mary\'s Rd", "No street light at Gandhi Nagar junction", "Child alone near the park"…',
                  hintStyle: const TextStyle(
                      color: AppColors.textLight, fontSize: 13),
                  fillColor: AppColors.bg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final txt = contentCtrl.text.trim();
                    if (txt.isEmpty) return;
                    await _dataSvc.createPost(CommunityPost(
                      id: '',
                      authorId: _user!.uid,
                      authorName: _user!.displayName ?? 'Parent',
                      authorPhotoUrl: _user!.photoURL,
                      content: txt,
                      category: selCat,
                      isVerified: true,
                      createdAt: DateTime.now(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Post Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String currentUid;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
  });

  static const _catMeta = {
    'missing_child': ('🆘', Color(0xFFFF1744), 'Missing Child'),
    'hazard':        ('⚠️', Color(0xFFFF9100), 'Hazard'),
    'suspicious':    ('👁️', Color(0xFF9B8FD4), 'Suspicious'),
    'child_alone':   ('👶', Color(0xFFFFB347), 'Child Alone'),
    'general':       ('📢', Color(0xFF2D9B8A), 'General'),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _catMeta[post.category] ??
        ('📢', AppColors.teal, 'General');
    final catEmoji = meta.$1;
    final catColor = meta.$2;
    final catLabel = meta.$3;
    final liked = post.likedBy.contains(currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.tealLight,
                backgroundImage: post.authorPhotoUrl != null
                    ? NetworkImage(post.authorPhotoUrl!)
                    : null,
                child: post.authorPhotoUrl == null
                    ? const Icon(Icons.person, color: AppColors.teal, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(post.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    if (post.isVerified)
                      const Icon(Icons.verified_rounded,
                          color: AppColors.teal, size: 14),
                  ]),
                  Text(timeago.format(post.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              )),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withOpacity(0.4)),
                ),
                child: Text(
                  '$catEmoji $catLabel',
                  style: TextStyle(
                      color: catColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(post.content,
                style: const TextStyle(
                    color: AppColors.textDark, fontSize: 14, height: 1.5)),
          ),

          if (post.locationLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(children: [
                const Icon(Icons.place_rounded, size: 13, color: AppColors.teal),
                const SizedBox(width: 3),
                Text(post.locationLabel!,
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),

          // ── Action bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(children: [
              // Like
              _ActionBtn(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                color: liked ? AppColors.coral : AppColors.textLight,
                onTap: onLike,
              ),
              const SizedBox(width: 4),
              // Comment
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
                color: AppColors.textLight,
                onTap: () {},
              ),
              const Spacer(),
              // Share
              _ActionBtn(
                icon: Icons.share_rounded,
                label: 'Share',
                color: AppColors.textLight,
                onTap: () {},
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.label,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}