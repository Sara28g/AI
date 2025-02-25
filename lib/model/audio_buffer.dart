class AudioBuffer {
  final List<double> levels;
  final String filePath;
  final String? photoPath;  // Add this field
  final DateTime timestamp;

  AudioBuffer({
    required this.levels,
    required this.filePath,
    this.photoPath,  // Add this parameter
    required this.timestamp,
  });
}