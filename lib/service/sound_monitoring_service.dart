import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:audio_session/audio_session.dart';
import 'photo_monitoring_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:collection';
import '../model/audio_buffer.dart';

class SoundMonitoringService with ChangeNotifier {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _recorderSubscription;
  bool _isMonitoring = false;
  bool _isPlaying = false;
  String? currentlyPlayingPath;
  double _currentDecibels = 0.0;
  double _maxDecibels = 0.0;
  List<double> _decibelHistory = [];
  Queue<String> _bufferFiles = Queue<String>();
  List<AudioBuffer> _highDecibelBuffers = [];
  String? _currentRecordingPath;
  DateTime? _thresholdExceededTime;
  bool _isCapturingEvent = false;
  final CameraService _cameraService;

  // Update the constructor to accept CameraService





  static const int MAX_HISTORY_LENGTH = 100;
  static const double DECIBEL_THRESHOLD = 60.0;
  static const int BUFFER_DURATION_SEC = 12; // One minute recording duration
  static const int SEGMENT_DURATION_MS = 500;
  bool _isAlertShowing = false;


  SoundMonitoringService(this._cameraService) {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _decibelHistory = [];
    _bufferFiles = Queue<String>();
    _highDecibelBuffers = [];
  }


  bool get isMonitoring => _isMonitoring;
  bool get isAlertNeeded => _isAlertShowing;
  double get currentDecibels => _currentDecibels;
  double get maxDecibels => _maxDecibels;
  List<double> get decibelHistory => _decibelHistory;
  List<AudioBuffer> get highDecibelBuffers => _highDecibelBuffers;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));

    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder!.openRecorder();
    await _player!.openPlayer();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: SEGMENT_DURATION_MS));

    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    final directory = await getExternalStorageDirectory();
    final recordingsDir = Directory('${directory!.path}/sound_recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
  }

  Future<String> _generateRecordingPath({bool isBuffer = false}) async {
    final directory = await getExternalStorageDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
    final prefix = isBuffer ? 'buffer' : 'event';
    return '${directory!.path}/sound_recordings/${prefix}_$timestamp.wav';
  }

  Future<void> _startNewBufferSegment() async {
    try {
      _currentRecordingPath = await _generateRecordingPath(isBuffer: true);
      debugPrint('Starting buffer segment: $_currentRecordingPath');

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16WAV,
        audioSource: AudioSource.microphone,
      );

      _bufferFiles.addLast(_currentRecordingPath!);

      while (_bufferFiles.length > BUFFER_DURATION_SEC) {
        final oldFile = _bufferFiles.removeFirst();
        if (oldFile.contains('buffer_')) {
          File(oldFile).delete().catchError((e) => debugPrint('Error deleting buffer: $e'));
        }
      }
    } catch (e) {
      debugPrint('Error starting buffer segment: $e');
    }
  }

  Future<String?> _combineAudioFiles(List<String> filePaths) async {
    try {
      final outputPath = await _generateRecordingPath();
      final outputFile = File(outputPath);
      final outputSink = outputFile.openWrite();

      for (String path in filePaths) {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsBytes();
          outputSink.add(content);
        }
      }

      await outputSink.close();
      return outputPath;
    } catch (e) {
      debugPrint('Error combining audio files: $e');
      return null;
    }
  }

  Future<void> startMonitoring() async {
    if (!_isMonitoring && _recorder != null) {
      try {
        await _startNewBufferSegment();

        _recorderSubscription = _recorder!.onProgress!.listen((event) async {
          _currentDecibels = event.decibels ?? 0;

          if (_currentDecibels > _maxDecibels) {
            _maxDecibels = _currentDecibels;
          }

          if (_currentDecibels > DECIBEL_THRESHOLD && !_isCapturingEvent) {
            _isCapturingEvent = true;
            _thresholdExceededTime = DateTime.now();

            // Take photo and log the path

            final photoPath = await _cameraService.takePhoto();
            debugPrint('Captured photo path: $photoPath');


            final allFiles = [..._bufferFiles];
            if (_currentRecordingPath != null) {
              allFiles.add(_currentRecordingPath!);
            }

            final combinedPath = await _combineAudioFiles(allFiles);
            if (combinedPath != null) {
              // Add debug logging for the AudioBuffer creation
              final buffer = AudioBuffer(
                levels: _decibelHistory.length > BUFFER_DURATION_SEC
                    ? List.from(_decibelHistory.sublist(_decibelHistory.length - BUFFER_DURATION_SEC))
                    : List.from(_decibelHistory),
                filePath: combinedPath,
                photoPath: photoPath,  // Store the photo path
                timestamp: _thresholdExceededTime!,
              );
              _highDecibelBuffers.add(buffer);
              debugPrint('Created AudioBuffer with photo path: ${buffer.photoPath}');
            }
          } else if (_isCapturingEvent &&
              _thresholdExceededTime != null &&
              DateTime.now().difference(_thresholdExceededTime!).inSeconds >= BUFFER_DURATION_SEC) {
            final allFiles = [..._bufferFiles];
            if (_currentRecordingPath != null) {
              allFiles.add(_currentRecordingPath!);
            }

            final combinedPath = await _combineAudioFiles(allFiles);
            if (combinedPath != null) {
              _highDecibelBuffers.add(AudioBuffer(
                levels: _decibelHistory.length > BUFFER_DURATION_SEC
                    ? List.from(_decibelHistory.sublist(_decibelHistory.length - BUFFER_DURATION_SEC))
                    : List.from(_decibelHistory),
                filePath: combinedPath,
                timestamp: _thresholdExceededTime!,
              ));
            }

            _isCapturingEvent = false;
            _isAlertShowing = false;
            _thresholdExceededTime = null;

            await _startNewBufferSegment();
            notifyListeners();
          } else if (!_isCapturingEvent &&
              DateTime.now().millisecondsSinceEpoch % SEGMENT_DURATION_MS < 100) {
            await _startNewBufferSegment();
          }

          _updateDecibelHistory(_currentDecibels);
          notifyListeners();
        });

        _isMonitoring = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Error starting monitoring: $e');
        _isMonitoring = false;
        notifyListeners();
      }
    }
  }

  Future<void> playRecording(String filePath) async {
    if (_isPlaying) {
      await stopPlayback();
    }

    try {
      _isPlaying = true;
      currentlyPlayingPath = filePath;
      notifyListeners();

      await _player!.startPlayer(
        fromURI: filePath,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          _isPlaying = false;
          currentlyPlayingPath = null;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _isPlaying = false;
      currentlyPlayingPath = null;
      notifyListeners();
    }
  }

  Future<void> stopPlayback() async {
    if (_isPlaying) {
      try {
        await _player!.stopPlayer();
        _isPlaying = false;
        currentlyPlayingPath = null;
        notifyListeners();
      } catch (e) {
        debugPrint('Error stopping playback: $e');
      }
    }
  }

  void _updateDecibelHistory(double decibels) {
    _decibelHistory.add(decibels);
    if (_decibelHistory.length > MAX_HISTORY_LENGTH) {
      _decibelHistory.removeAt(0);
    }
  }

  Future<void> stopMonitoring() async {
    if (_isMonitoring) {
      try {
        await _recorder!.stopRecorder();
        await _recorderSubscription?.cancel();

        for (final path in _bufferFiles) {
          if (path.contains('buffer_')) {
            File(path).delete().catchError((e) => debugPrint('Error deleting buffer: $e'));
          }
        }
        _bufferFiles.clear();
      } catch (e) {
        debugPrint('Error stopping monitoring: $e');
      } finally {
        _isMonitoring = false;
        _maxDecibels = 0.0;
        _isCapturingEvent = false;
        _thresholdExceededTime = null;
        notifyListeners();
      }
    }
  }

  Future<void> deleteRecording(int index) async {
    try {
      final recording = _highDecibelBuffers[index];
      if (recording.filePath == currentlyPlayingPath) {
        await stopPlayback();
      }
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _highDecibelBuffers.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    stopPlayback();
    _recorder!.closeRecorder();
    _player!.closePlayer();
    super.dispose();
  }
}
