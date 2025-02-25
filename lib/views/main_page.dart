// lib/pages/main_page.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'recordings_page.dart';
import '../service/sound_monitoring_service.dart';
import 'widgets/decibel_display_card.dart';
import 'widgets/decibel_graph.dart';

class MainPagem extends StatefulWidget {
  const MainPagem({Key? key}) : super(key: key);

  @override
  _MainPagemState createState() => _MainPagemState();
}

class _MainPagemState extends State<MainPagem> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      await context.read<SoundMonitoringService>().initialize();
    }
    context.read<SoundMonitoringService>().startMonitoring();
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('High Sound Level Alert'),
            ],
          ),
          content: Text(
            'The current sound level has exceeded ${SoundMonitoringService.DECIBEL_THRESHOLD} dB.\n\n'
                'Prolonged exposure to loud sounds can be harmful to your hearing.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Acknowledge'),
            ),
          ],
        );
      },
    );
  }

  // Update the AppBar in MainPage's build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.audio_file),
                Consumer<SoundMonitoringService>(
                  builder: (context, service, child) {
                    if (service.highDecibelBuffers.isEmpty) return const SizedBox();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${service.highDecibelBuffers.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecordingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      /*body: _hasPermission ? _buildMainContent() : _buildPermissionRequest(),*/
    );
  }
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off, size: 64),
            const SizedBox(height: 24),
            Text(
              'Microphone Access Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Please grant microphone access to monitor sound levels.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.mic),
              label: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<SoundMonitoringService>(
      builder: (context, service, child) {
        if (service.isAlertNeeded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAlert(context);
          });
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(service),
              const SizedBox(height: 24),
              DecibelDisplayCard(service: service),
              const SizedBox(height: 24),
              _buildControlButton(service),
              const SizedBox(height: 24),
              Expanded(
                child: _buildDecibelGraph(service),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(SoundMonitoringService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: service.isMonitoring ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              service.isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(SoundMonitoringService service) {
    return FilledButton.icon(
      onPressed: () {
        if (service.isMonitoring) {
          service.stopMonitoring();
        } else {
          service.startMonitoring();
        }
      },
      icon: Icon(service.isMonitoring ? Icons.stop : Icons.play_arrow),
      label: Text(service.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
    );
  }

  Widget _buildDecibelGraph(SoundMonitoringService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound Level History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DecibelGraphPainter(
                decibelHistory: service.decibelHistory,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
