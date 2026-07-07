import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/recognition_provider.dart';
import '../../data/models/recognition_model.dart';
import '../../core/theme/app_theme.dart';
import '../result/result_screen.dart';
import '../auth/login_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<RecognitionProvider>().loadHistory(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text('Sign in to see your history', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecognitionProvider>().loadHistory(refresh: true),
          ),
        ],
      ),
      body: Consumer<RecognitionProvider>(
        builder: (_, provider, __) {
          if (provider.historyLoading && provider.history.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (provider.history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('No songs recognized yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tap the button on the home screen to start!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => provider.loadHistory(refresh: true),
            child: ListView.builder(
              itemCount: provider.history.length + (provider.hasMoreHistory ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == provider.history.length) {
                  if (!provider.historyLoading) {
                    provider.loadHistory();
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }
                return _HistoryItem(
                  recognition: provider.history[i],
                  onDelete: () => provider.deleteHistoryItem(provider.history[i].id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Recognition recognition;
  final VoidCallback onDelete;

  const _HistoryItem({required this.recognition, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(recognition.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(song: recognition.toSong())),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: recognition.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: recognition.coverUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recognition.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(recognition.artist, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • HH:mm').format(recognition.recognizedAt.toLocal()),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(width: 56, height: 56, color: AppTheme.surface,
        child: const Icon(Icons.music_note, color: AppTheme.primary, size: 28));
  }
}
