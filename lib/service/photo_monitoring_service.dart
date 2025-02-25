import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class CameraService with ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _lastPhotoPath;
  List<CameraDescription>? _cameras;
  FlashMode _currentFlashMode = FlashMode.off;
  double _currentZoomLevel = 1.0;
  final double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.5;

  bool get isInitialized => _isInitialized;
  String? get lastPhotoPath => _lastPhotoPath;
  CameraController? get controller => _controller;
  FlashMode get currentFlashMode => _currentFlashMode;
  double get currentZoomLevel => _currentZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;
  double get minZoomLevel => _minZoomLevel;

  Future<bool> initialize() async {
    try {
      debugPrint('Starting camera initialization');

      // Check permissions first
      final cameraStatus = await Permission.camera.status;
      debugPrint('Camera permission status: $cameraStatus');

      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        debugPrint('Camera permission request result: $result');
        if (!result.isGranted) {
          debugPrint('Camera permission denied');
          return false;
        }
      }

      // Get available cameras
      _cameras = await availableCameras();
      debugPrint('Found ${_cameras?.length ?? 0} cameras');

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Find and prioritize the front camera
      CameraDescription frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0], // Fallback to first camera if no front camera
      );

      // Initialize the controller with the front camera
      await _initializeController(frontCamera);
      debugPrint('Camera initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Camera initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }



  Future<void> _initializeController(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _currentFlashMode = _controller!.value.flashMode;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
      notifyListeners();
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<String?> takePhoto() async {
    if (_controller == null || !_isInitialized) {
      initialize();
      debugPrint('Camera not initialized');
      return null;
    }

    try {
      // Create directory for saving photos
      final directory = await getExternalStorageDirectory();
      final recordingsDir = Directory('${directory!.path}/sound_recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Take the picture
      final XFile photo = await _controller!.takePicture();

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.jpg';
      final filePath = path.join(recordingsDir.path, fileName);

      // Copy the photo to our app's directory
      await File(photo.path).copy(filePath);

      _lastPhotoPath = filePath;
      notifyListeners();
      debugPrint('Photo saved successfully at: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  Future<bool> switchCamera() async {
    if (_controller == null || !_isInitialized || _cameras == null || _cameras!.length < 2) {
      return false;
    }

    try {
      final currentCameraIndex = _cameras!.indexOf(_controller!.description);
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

      await _initializeController(_cameras![newCameraIndex]);
      return true;
    } catch (e) {
      debugPrint('Error switching camera: $e');
      return false;
    }
  }

  Future<bool> setZoomLevel(double zoom) async {
    if (_controller == null || !_isInitialized) {
      return false;
    }

    try {
      zoom = zoom.clamp(_minZoomLevel, _maxZoomLevel);
      await _controller!.setZoomLevel(zoom);
      _currentZoomLevel = zoom;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
      return false;
    }
  }

  Future<bool> toggleFlash() async {
    if (_controller == null || !_isInitialized) {
      return false;
    }

    try {
      FlashMode newMode;
      switch (_currentFlashMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        default:
          newMode = FlashMode.off;
          break;
      }

      await _controller!.setFlashMode(newMode);
      _currentFlashMode = newMode;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      return false;
    }
  }

  Future<bool> pausePreview() async {
    if (_controller == null || !_isInitialized) {
      return false;
    }

    try {
      await _controller!.pausePreview();
      return true;
    } catch (e) {
      debugPrint('Error pausing preview: $e');
      return false;
    }
  }

  Future<bool> resumePreview() async {
    if (_controller == null || !_isInitialized) {
      return false;
    }

    try {
      await _controller!.resumePreview();
      return true;
    } catch (e) {
      debugPrint('Error resuming preview: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    super.dispose();
  }
}