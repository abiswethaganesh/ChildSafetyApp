// lib/screens/home_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/data_service.dart';
import '../utils/app_theme.dart';
import '../widgets/child_map_marker.dart';
import '../widgets/sos_sheet.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});
  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final _mapCtrl = MapController();
  final _dataSvc = DataService();

  LatLng _myLoc      = const LatLng(13.0827, 80.2707);
  bool _locLoaded    = false;
  bool _showRedZones = true; // toggle via button at top
  ChildProfile? _focusedChild;

  List<ChildProfile> _children  = [];
  List<RedZone>      _redZones  = [];
  List<AppAlert>     _alerts    = [];
  List<SosEvent>     _activeSos = [];

  // Demo alerts shown until real Firestore alerts exist
  final List<_DemoAlert> _demoAlerts = [
    _DemoAlert(
      emoji: '💓',
      title: "Child's heart rate was high",
      detail: 'Heart rate spiked to 142 bpm at 2:34 PM near school.',
      color: Color(0xFFFF6B6B),
    ),
    _DemoAlert(
      emoji: '🏃',
      title: 'Unusual movement detected',
      detail: 'Device detected running at unusual speed — possible fall risk.',
      color: Color(0xFFFFB347),
    ),
    _DemoAlert(
      emoji: '📍',
      title: 'Child left trusted zone',
      detail: 'Child moved 350m away from school at 3:05 PM.',
      color: Color(0xFF9B8FD4),
    ),
  ];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName?.split(' ').first
          ?? 'Parent';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _watchData();
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _myLoc     = LatLng(pos.latitude, pos.longitude);
        _locLoaded = true;
      });
      _mapCtrl.move(_myLoc, 15);
    } catch (_) {}
  }

  void _watchData() {
    if (_uid.isEmpty) return;
    _dataSvc.watchChildren(_uid).listen((c) {
      if (!mounted) return;
      setState(() => _children = c);
      if (c.isNotEmpty && c.first.location != null) {
        _mapCtrl.move(c.first.location!, 15);
      }
    });
    // Reads lat/lng/radiusM/severity correctly from your Firestore red_zones collection
    _dataSvc.watchRedZones().listen((z) {
      if (!mounted) return;
      setState(() => _redZones = z);
    });
    _dataSvc.watchAlerts(_uid).listen((a) {
      if (!mounted) return;
      setState(() => _alerts = a);
    });
    _dataSvc.watchActiveSos(_uid).listen((s) {
      if (!mounted) return;
      setState(() => _activeSos = s);
      if (s.isNotEmpty) _showSosSheet(s.first);
    });
  }

  void _showSosSheet(SosEvent e) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => SosSheet(
        event: e,
        onRespond: () {
          _dataSvc.respondSos(e.id);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _distanceLabel(ChildProfile child) {
    if (child.location == null) return 'Location unknown';
    const dist = Distance();
    String closest = '';
    double minDist = double.infinity;
    for (final tp in child.trustedPlaces) {
      final d = dist.as(LengthUnit.Meter, child.location!, tp.location);
      if (d < minDist) { minDist = d; closest = tp.label; }
    }
    if (closest.isEmpty) return 'No trusted places set';
    if (minDist < 50)    return 'At $closest ✅';
    if (minDist < 1000)  return '${minDist.toInt()}m from $closest';
    return '${(minDist / 1000).toStringAsFixed(1)}km from $closest';
  }

  void _showCheckOnChildDialog(String childName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
                color: AppColors.tealLight, shape: BoxShape.circle),
            child: const Center(
                child: Text('👶', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 14),
          Text('Check on $childName',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('What would you like to do?',
              style: TextStyle(color: AppColors.textMid, fontSize: 14)),
          const SizedBox(height: 20),
          _CheckOption(icon: Icons.phone_rounded,   color: AppColors.teal,
              label: "Call child's device",        onTap: () => Navigator.pop(context)),
          const SizedBox(height: 10),
          _CheckOption(icon: Icons.map_rounded,      color: AppColors.lavender,
              label: 'See live location on map',   onTap: () => Navigator.pop(context)),
          const SizedBox(height: 10),
          _CheckOption(icon: Icons.message_rounded,  color: AppColors.amber,
              label: 'Send a safe message',        onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  Widget _buildMap() {
    final childMarkers = _children
        .where((c) => c.location != null)
        .map((c) => Marker(
              point: c.location!,
              width: 64, height: 80,
              child: ChildMapMarker(child: c),
            ))
        .toList();

    final myMarker = _locLoaded
        ? [Marker(
            point: _myLoc, width: 40, height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 3),
                boxShadow: [BoxShadow(
                    color: AppColors.teal.withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.teal, size: 20),
            ),
          )]
        : <Marker>[];

    // Uses radiusM from Firestore — your DB has 300 which will now show correctly
    final redCircles = _showRedZones
        ? _redZones.map((z) {
            Color fill; Color stroke;
            switch (z.severity) {
              case 'high':
                fill = AppColors.coral.withOpacity(0.22);
                stroke = AppColors.coral;
              case 'medium':
                fill = AppColors.amber.withOpacity(0.20);
                stroke = AppColors.amber;
              default:
                fill = Colors.orange.withOpacity(0.15);
                stroke = Colors.orange;
            }
            return CircleMarker(
              point: z.center,
              radius: z.radiusM,       // ← was hardcoded 1000, now reads from Firestore
              useRadiusInMeter: true,
              color: fill,
              borderColor: stroke,
              borderStrokeWidth: 2.5,
            );
          }).toList()
        : <CircleMarker>[];

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _myLoc,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.guardian.app',
        ),
        if (_showRedZones && redCircles.isNotEmpty)
          CircleLayer(circles: redCircles),
        MarkerLayer(markers: [...myMarker, ...childMarkers]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),

          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(
              displayName: _displayName,
              showRedZones: _showRedZones,
              redZoneCount: _redZones.length,
              onToggleRedZones: () =>
                  setState(() => _showRedZones = !_showRedZones),
              onCenterMe: () => _mapCtrl.move(_myLoc, 15),
            ),
          ),

          if (_children.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72 + 8,
              left: 0, right: 0,
              child: _ChildStrip(
                children: _children,
                focused: _focusedChild,
                onTap: (c) {
                  setState(() => _focusedChild = c);
                  if (c.location != null) _mapCtrl.move(c.location!, 16);
                },
              ),
            ),

          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.14,
            maxChildSize: 0.72,
            builder: (_, ctrl) => _BottomPanel(
              scrollCtrl: ctrl,
              children: _children,
              alerts: _alerts,
              demoAlerts: _demoAlerts,
              distanceLabel: _distanceLabel,
              onMarkRead: _dataSvc.markAlertRead,
              onCheckOnChild: _showCheckOnChildDialog,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo alert model ──────────────────────────────────────────────────────────
class _DemoAlert {
  final String emoji, title, detail;
  final Color color;
  bool dismissed;
  _DemoAlert({
    required this.emoji, required this.title,
    required this.detail, required this.color,
    this.dismissed = false,
  });
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String displayName;
  final bool showRedZones;
  final int redZoneCount;
  final VoidCallback onToggleRedZones;
  final VoidCallback onCenterMe;

  const _TopBar({
    required this.displayName, required this.showRedZones,
    required this.redZoneCount, required this.onToggleRedZones,
    required this.onCenterMe,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18, backgroundColor: AppColors.tealLight,
          backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
              ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
              : null,
          child: FirebaseAuth.instance.currentUser?.photoURL == null
              ? const Icon(Icons.person, color: AppColors.teal, size: 18)
              : null,
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hi, $displayName! 👋',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const Text('Family safety map',
              style: TextStyle(fontSize: 11, color: AppColors.textMid)),
        ]),
        const Spacer(),

        // Red zone toggle with badge count
        Stack(clipBehavior: Clip.none, children: [
          GestureDetector(
            onTap: onToggleRedZones,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: showRedZones
                    ? AppColors.coral.withOpacity(0.15) : AppColors.divider,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showRedZones ? AppColors.coral : Colors.transparent,
                  width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: showRedZones
                        ? AppColors.coral : AppColors.textLight,
                    size: 16),
                const SizedBox(width: 4),
                Text('Red Zones',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: showRedZones
                          ? AppColors.coral : AppColors.textMid)),
              ]),
            ),
          ),
          if (redZoneCount > 0)
            Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: AppColors.coral, shape: BoxShape.circle),
                child: Text('$redZoneCount',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
        const SizedBox(width: 8),

        GestureDetector(
          onTap: onCenterMe,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.teal, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ── Child strip ───────────────────────────────────────────────────────────────
class _ChildStrip extends StatelessWidget {
  final List<ChildProfile> children;
  final ChildProfile? focused;
  final ValueChanged<ChildProfile> onTap;
  const _ChildStrip(
      {required this.children, required this.focused, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = children[i]; final sel = focused?.id == c.id;
          return GestureDetector(
            onTap: () => onTap(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
              child: Text(c.name,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom panel (stateful so demo alerts can be dismissed) ───────────────────
class _BottomPanel extends StatefulWidget {
  final ScrollController scrollCtrl;
  final List<ChildProfile> children;
  final List<AppAlert> alerts;
  final List<_DemoAlert> demoAlerts;
  final String Function(ChildProfile) distanceLabel;
  final Future<void> Function(String) onMarkRead;
  final void Function(String) onCheckOnChild;

  const _BottomPanel({
    required this.scrollCtrl, required this.children,
    required this.alerts,     required this.demoAlerts,
    required this.distanceLabel, required this.onMarkRead,
    required this.onCheckOnChild,
  });

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> {
  @override
  Widget build(BuildContext context) {
    final useDemo = widget.alerts.isEmpty;
    final activeDemos = widget.demoAlerts.where((d) => !d.dismissed).toList();
    final childName = widget.children.isNotEmpty
        ? widget.children.first.name : 'your child';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(
            color: Color(0x18000000), blurRadius: 24,
            offset: Offset(0, -4))],
      ),
      child: CustomScrollView(
        controller: widget.scrollCtrl,
        slivers: [
          // Drag handle
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),

          // Children cards
          if (widget.children.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.children.length,
                  itemBuilder: (_, i) => _ChildInfoCard(
                    child: widget.children[i],
                    distLabel: widget.distanceLabel(widget.children[i]),
                  ),
                ),
              ),
            ),

          if (widget.children.isEmpty)
            SliverToBoxAdapter(child: _EmptyChildHint()),

          // Alerts heading
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(children: [
                const Icon(Icons.notifications_rounded,
                    color: AppColors.teal, size: 20),
                const SizedBox(width: 8),
                const Text('Recent Alerts',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17,
                        color: AppColors.textDark)),
                const Spacer(),
                if (useDemo && activeDemos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('${activeDemos.length} new',
                        style: const TextStyle(
                            color: AppColors.amber, fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ),

          // Demo alerts
          if (useDemo && activeDemos.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final a = activeDemos[i];
                  return _DemoAlertTile(
                    alert: a,
                    childName: childName,
                    onCheckOnChild: () => widget.onCheckOnChild(childName),
                    onDismiss: () => setState(() => a.dismissed = true),
                  ).animate().fadeIn(delay: (i * 60).ms);
                },
                childCount: activeDemos.length,
              ),
            ),

          // Real Firestore alerts
          if (!useDemo)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AlertTile(
                  alert: widget.alerts[i],
                  onTap: () => widget.onMarkRead(widget.alerts[i].id),
                  onCheckOnChild: () => widget.onCheckOnChild(childName),
                ).animate().fadeIn(delay: (i * 40).ms),
                childCount: widget.alerts.length,
              ),
            ),

          // All clear
          if ((useDemo && activeDemos.isEmpty) ||
              (!useDemo && widget.alerts.isEmpty))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(16)),
                  child: const Row(children: [
                    Text('✅', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(child: Text('All clear! No alerts right now.',
                        style: TextStyle(
                            color: AppColors.tealDark,
                            fontWeight: FontWeight.w700, fontSize: 14))),
                  ]),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── Demo alert tile with Check on Child + Dismiss buttons ─────────────────────
class _DemoAlertTile extends StatelessWidget {
  final _DemoAlert alert;
  final String childName;
  final VoidCallback onCheckOnChild;
  final VoidCallback onDismiss;

  const _DemoAlertTile({
    required this.alert, required this.childName,
    required this.onCheckOnChild, required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alert.color.withOpacity(0.28), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Body
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: alert.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(alert.emoji,
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alert.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 3),
              Text(alert.detail,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMid, height: 1.4)),
              const SizedBox(height: 4),
              Text('Just now',
                  style: TextStyle(
                      fontSize: 11, color: alert.color,
                      fontWeight: FontWeight.w700)),
            ])),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textLight, size: 16),
            ),
          ]),
        ),

        // Action strip
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: onCheckOnChild,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: alert.color,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18))),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text('Check on Child',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ]),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(18))),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded,
                          color: AppColors.textMid, size: 15),
                      SizedBox(width: 6),
                      Text('Dismiss',
                          style: TextStyle(
                              color: AppColors.textMid,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Real Firestore alert tile ─────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;
  final VoidCallback onCheckOnChild;

  const _AlertTile({
    required this.alert, required this.onTap, required this.onCheckOnChild});

  Color get _color {
    switch (alert.severity) {
      case 'critical': return AppColors.coral;
      case 'warning':  return AppColors.amber;
      default:         return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { if (!alert.isRead) onTap(); },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: alert.isRead ? AppColors.bg : _color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alert.isRead ? AppColors.divider : _color.withOpacity(0.35),
            width: alert.isRead ? 1 : 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.notifications_rounded,
                    color: _color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(alert.message,
                    style: TextStyle(
                      color: alert.isRead
                          ? AppColors.textMid : AppColors.textDark,
                      fontSize: 13,
                      fontWeight: alert.isRead
                          ? FontWeight.w500 : FontWeight.w700,
                      height: 1.4)),
                const SizedBox(height: 4),
                Text(timeago.format(alert.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
              ])),
              if (!alert.isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                      color: _color, shape: BoxShape.circle)),
            ]),
          ),
          if (alert.severity != 'info')
            GestureDetector(
              onTap: onCheckOnChild,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18))),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text('Check on Child',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Child info card ───────────────────────────────────────────────────────────
class _ChildInfoCard extends StatelessWidget {
  final ChildProfile child;
  final String distLabel;
  const _ChildInfoCard({required this.child, required this.distLabel});

  Color get _statusColor {
    switch (child.status) {
      case 'danger':  return AppColors.coral;
      case 'warning': return AppColors.amber;
      default:        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
                color: AppColors.tealLight, shape: BoxShape.circle),
            child: const Center(
                child: Text('👶', style: TextStyle(fontSize: 22))),
          ),
          Positioned(bottom: 0, right: 0,
            child: Container(
              width: 13, height: 13,
              decoration: BoxDecoration(
                color: _statusColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            ),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(child.name, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text('Age ${child.age}', style: const TextStyle(
                fontSize: 11, color: AppColors.textMid)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_rounded, size: 12, color: AppColors.teal),
              const SizedBox(width: 2),
              Expanded(child: Text(distLabel, style: const TextStyle(
                  fontSize: 11, color: AppColors.teal,
                  fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
            ]),
          ],
        )),
      ]),
    );
  }
}

class _EmptyChildHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.amberLight, borderRadius: BorderRadius.circular(18)),
        child: const Row(children: [
          Text('👶', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(child: Text(
            'Go to Profile → Manage Children to add a child',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
      ),
    );
  }
}

// ── Check on child option ─────────────────────────────────────────────────────
class _CheckOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _CheckOption({
    required this.icon, required this.color,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: color)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
        ]),
      ),
    );
  }
}