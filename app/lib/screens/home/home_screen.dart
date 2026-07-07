import 'dart:async';
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
import 'widgets/ripple_button.dart';
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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecognitionProvider>().loadTrending();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Check microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to identify songs')),
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
        MaterialPageRoute(builder: (_) => ResultScreen(song: provider.recognizedSong!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Song not recognized. Try again.'),
          backgroundColor: AppTheme.error,
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppTheme.background,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.graphic_eq, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('Soundwave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              if (auth.isAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      auth.user!.username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Main listen button area
                _buildListenSection(recognition),
                const SizedBox(height: 60),
                // Trending section
                const TrendingSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenSection(RecognitionProvider recognition) {
    if (recognition.state == RecognitionState.processing) {
      return Column( // ignore: prefer_const_constructors
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Identifying...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Listening to the audio...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ).animate().fadeIn();
    }

    return Column(
      children: [
        Text(
          _isListening ? 'Listening...' : 'Tap to identify',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
        RippleButton(
          isListening: _isListening,
          onTap: _isListening ? _cancelListening : _startListening,
        ),
        const SizedBox(height: 24),
        if (_isListening) ...[
          Text(
            '$_secondsRemaining s',
            style: const TextStyle(color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancelListening,
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ] else
          const Text(
            AppConstants.appTagline,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
