import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class RippleButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const RippleButton({super.key, required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening) ...[
            // Ripple rings
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.08),
              ),
            ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.8, end: 1.2, duration: 1200.ms, curve: Curves.easeOut).fadeOut(begin: 0.8, duration: 1200.ms),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
              ),
            ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.85, end: 1.15, duration: 1200.ms, delay: 200.ms, curve: Curves.easeOut).fadeOut(begin: 0.9, duration: 1200.ms, delay: 200.ms),
          ],
          // Main button
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [AppTheme.accent, AppTheme.primary]
                    : [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.graphic_eq,
              size: 60,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
