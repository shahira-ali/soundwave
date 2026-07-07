import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/recognition_provider.dart';
import '../../data/services/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../result/result_screen.dart';
import 'widgets/trending_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  Timer? _recordingTimer;
  int _secondsRemaining = 10;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecognitionProvider>().loadTrending();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotateController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _secondsRemaining = AppConstants.recordingDuration.inSeconds;
    });

    await AudioService.startRecording();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _stopAndRecognize();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _stopAndRecognize() async {
    _recordingTimer?.cancel();
    final file = await AudioService.stopRecording();
    setState(() => _isListening = false);

    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record audio. Try again.')),
        );
      }
      return;
    }

    if (!mounted) return;
    final provider = context.read<RecognitionProvider>();
    await provider.recognize(file);

    if (!mounted) return;
    if (provider.state == RecognitionState.found && provider.recognizedSong != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => ResultScreen(song: provider.recognizedSong!),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Song not recognized. Try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _cancelListening() {
    _recordingTimer?.cancel();
    AudioService.stopRecording();
    setState(() {
      _isListening = false;
      _secondsRemaining = AppConstants.recordingDuration.inSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recognition = context.watch<RecognitionProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (_, __) => Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (_, __) => Transform.rotate(
                angle: -_rotateController.value * 2 * math.pi,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.accent],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.graphic_eq, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SoundWave',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (auth.isAuthenticated)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                auth.user!.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Listen section
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: size.height * 0.52,
                    child: _buildListenSection(recognition),
                  ),
                ),

                // Trending
                const SliverToBoxAdapter(child: TrendingSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenSection(RecognitionProvider recognition) {
    if (recognition.state == RecognitionState.processing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Processing animation
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) {
              return SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _WavePainter(_waveController.value),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Identifying...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Matching with millions of songs',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isListening ? 'Listening...' : 'Tap to identify',
            key: ValueKey(_isListening),
            style: TextStyle(
              color: _isListening ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Main button
        GestureDetector(
          onTap: _isListening ? _cancelListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final scale = _isListening
                  ? 1.0 + (_pulseController.value * 0.06)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow rings
                if (_isListening) ...[
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (_, __) {
                      final val = _waveController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - val).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 1.0 + val * 0.6,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: ((1 - (val + 0.4).clamp(0.0, 1.0))).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 1.0 + ((val + 0.4) % 1.0) * 0.6,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                // Button circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [AppTheme.accent, AppTheme.primary]
                          : [AppTheme.primary, const Color(0xFF9C6FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppTheme.accent : AppTheme.primary)
                            .withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.graphic_eq_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Timer / tagline
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isListening
              ? Column(
                  key: const ValueKey('listening'),
                  children: [
                    // Countdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
                          const SizedBox(width: 8),
                          Text(
                            '$_secondsRemaining seconds remaining',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cancelListening,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('idle'),
                  children: [
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// Wave painter for processing animation
class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final delay = i * 0.25;
      final t = (progress + delay) % 1.0;
      final radius = 20.0 + t * 70.0;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      paint.color = (i % 2 == 0 ? AppTheme.primary : AppTheme.accent)
          .withValues(alpha: opacity * 0.8);
      paint.strokeWidth = 2.5 - t * 1.5;
      canvas.drawCircle(center, radius, paint);
    }

    // Center dot
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
