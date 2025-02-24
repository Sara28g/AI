import 'package:flutter/material.dart';
import 'package:projectaig/views/HelpMap.dart';
import 'package:video_player/video_player.dart';
import 'homepage.dart';
import 'nav.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/introVideo.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(false);
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NavigationLayout()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          // Background Video
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover, // Ensures full-screen fill
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // Optional: Black overlay to improve contrast
          Container(
            color: Colors.black.withOpacity(0.1), // Light overlay
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
