import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static String? _recordingPath;

  static Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  static Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/soundwave_sample.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );
  }

  static Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
      return File(path);
    }
    return null;
  }

  static Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  static Future<void> dispose() async {
    await _recorder.dispose();
  }
}
