// lib/pages/recordings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../model/audio_buffer.dart';
import '../service/sound_monitoring_service.dart';
import 'package:projectaig/views/recordings_page.dart';


class RecordingsPage extends StatefulWidget {
  const RecordingsPage({Key? key}) : super(key: key);

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Recordings' : 'Photos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SoundMonitoringService>(
        builder: (context, service, child) {
          final recordings = service.highDecibelBuffers;

          if (recordings.isEmpty) {
            return const Center(
              child: Text('No recordings available'),
            );
          }

          return _selectedIndex == 0
              ? _buildRecordingsList(recordings, service)
              : _buildPhotoGrid(recordings);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.audio_file),
            label: 'Recordings',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(List<AudioBuffer> recordings, SoundMonitoringService service) {
    return ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        final recording = recordings[index];

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Recording ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Recorded on: ${recording.timestamp.toString()}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await service.playRecording(recording.filePath);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Audio'),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await service.deleteRecording(index);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid(List<AudioBuffer> recordings) {
    // Add debug logging for photo checking
    debugPrint('Checking photos in ${recordings.length} recordings');

    final photos = recordings.where((recording) {
      debugPrint('Checking recording photo path: ${recording.photoPath}');
      if (recording.photoPath == null) {
        return false;
      }

      final file = File(recording.photoPath!);
      final exists = file.existsSync();
      debugPrint('Photo file exists: $exists at path: ${recording.photoPath}');
      return exists;
    }).toList();

    if (photos.isEmpty) {
      return const Center(
        child: Text('No photos available'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  debugPrint('Stack trace: $stackTrace');
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.black54,
                  child: Text(
                    photo.timestamp.toString(),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}