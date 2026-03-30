// lib/widgets/child_map_marker.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class ChildMapMarker extends StatefulWidget {
  final ChildProfile child;
  const ChildMapMarker({super.key, required this.child});

  @override
  State<ChildMapMarker> createState() => _ChildMapMarkerState();
}

class _ChildMapMarkerState extends State<ChildMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _ringColor {
    switch (widget.child.status) {
      case 'danger':  return AppColors.coral;
      case 'warning': return AppColors.amber;
      default:        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Bubble ─────────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Transform.scale(
            scale: _pulse.value,
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _ringColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _ringColor, width: 2.5),
                ),
              ),
              // White circle
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 22)),
                ),
              ),
              // Status dot
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _ringColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Name label ─────────────────────────────────────────────────────
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1), blurRadius: 6)
            ],
          ),
          child: Text(
            widget.child.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        // ── Pointer triangle ───────────────────────────────────────────────
        CustomPaint(
          size: const Size(12, 7),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}