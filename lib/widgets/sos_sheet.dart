// lib/widgets/sos_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class SosSheet extends StatelessWidget {
  final SosEvent event;
  final VoidCallback onRespond;
  const SosSheet({super.key, required this.event, required this.onRespond});

  String get _title {
    switch (event.type) {
      case 'fall':    return '🚨 Fall Detected!';
      case 'kidnap':  return '🚨 Kidnap Alert!';
      case 'manual':  return '🆘 Child triggered SOS!';
      default:        return '🚨 Emergency!';
    }
  }

  String get _desc {
    switch (event.type) {
      case 'fall':   return 'The IoT watch detected a sudden fall. Check on your child immediately.';
      case 'kidnap': return 'Sudden forceful movement detected. Your child may be in danger!';
      case 'manual': return 'Your child manually activated the SOS. They need you now.';
      default:       return 'An emergency was detected on your child\'s device.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red top strip
          Container(
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Pulsing SOS icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.coral, width: 3),
                ),
                child: const Center(
                  child: Text('🆘', style: TextStyle(fontSize: 38)),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0),
                      duration: 800.ms),
              const SizedBox(height: 16),
              Text(_title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.coral)),
              const SizedBox(height: 8),
              Text(_desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMid, fontSize: 14, height: 1.5)),
              const SizedBox(height: 8),
              Text(
                '⏱ You have 2 minutes to respond\nbefore nearby parents are notified',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRespond,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("I'm responding now!",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View on map',
                    style: TextStyle(
                        color: AppColors.teal, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}