import 'package:flutter/material.dart';
import 'package:flux/main.dart';

class VideoViewer extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final int index;
  const VideoViewer({super.key, required this.videos, required this.index});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          scrollDirection: Axis.vertical,
          controller: PageController(initialPage: index),
          itemCount: videos.length,
          itemBuilder: (_, i) =>
              VideoPage(key: ValueKey(videos[i]['id']), v: videos[i]),
        ),
        SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ]),
    );
  }
}
