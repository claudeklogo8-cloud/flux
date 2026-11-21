import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const FluxApp());

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(primary: Color(0xFFFF8A00))),
        home: const Feed(),
      );
}

const urls = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
];

class Feed extends StatelessWidget {
  const Feed({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        body: PageView.builder(
          scrollDirection: Axis.vertical,
          itemBuilder: (_, i) => VideoPage(url: urls[i % urls.length]),
        ),
      );
}

class VideoPage extends StatefulWidget {
  final String url;
  const VideoPage({super.key, required this.url});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController ctrl;
  bool liked = false;
  int likes = 0;

  @override
  void initState() {
    super.initState();
    ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          ctrl.play();
        }
      });
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return GestureDetector(
      onTap: () => setState(
          () => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play()),
      child: Stack(fit: StackFit.expand, children: [
        ctrl.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                    width: ctrl.value.size.width,
                    height: ctrl.value.size.height,
                    child: VideoPlayer(ctrl)))
            : const Center(child: CircularProgressIndicator()),
        Positioned(
            right: 12,
            bottom: 100,
            child: Column(children: [
              IconButton(
                  iconSize: 36,
                  icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.orange : Colors.white),
                  onPressed: () => setState(() {
                        liked = !liked;
                        likes += liked ? 1 : -1;
                      })),
              Text('$likes'),
              const SizedBox(height: 16),
              const Icon(Icons.chat_bubble_outline, size: 34),
              const SizedBox(height: 16),
              const Icon(Icons.share, size: 34),
            ])),
        const Positioned(
            left: 16,
            bottom: 40,
            child: Text('@utilisateur',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16))),
      ]),
    );
  }
}
