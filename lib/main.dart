import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const FluxApp());

const bleu = Color(0xFF1E88E5);
const bleuClair = Color(0xFF42A5F5);

const urls = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
];

void bientot(BuildContext c) {
  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
      content: Text('Bientôt disponible'),
      duration: Duration(seconds: 1)));
}

Widget onglet(BuildContext c, String label, bool actif) {
  return GestureDetector(
    onTap: () => bientot(c),
    child: Text(label,
        style: TextStyle(
            fontSize: 17,
            fontWeight: actif ? FontWeight.bold : FontWeight.normal,
            color: actif ? Colors.white : Colors.white70,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)])),
  );
}

Widget navItem(BuildContext c, IconData icon, String label, bool actif) {
  return GestureDetector(
    onTap: () => bientot(c),
    behavior: HitTestBehavior.opaque,
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: actif ? bleuClair : Colors.white),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: actif ? bleuClair : Colors.white)),
        ]),
  );
}

Widget barreBas(BuildContext c) {
  return Container(
    color: Colors.black,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(c, Icons.person_outline, 'Profil', false),
              navItem(c, Icons.group_outlined, 'Amis', false),
              GestureDetector(
                onTap: () => bientot(c),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                      color: bleu, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Créer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              navItem(c, Icons.mail_outline, 'Message', false),
              navItem(c, Icons.home, 'Accueil', true),
            ]),
      ),
    ),
  );
}

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: bleu)),
        home: const Shell(),
      );
}

class Shell extends StatelessWidget {
  const Shell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemBuilder: (_, i) => VideoPage(url: urls[i % urls.length]),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    onglet(context, 'Live', false),
                    const SizedBox(width: 18),
                    onglet(context, 'Suivis', false),
                    const SizedBox(width: 18),
                    onglet(context, 'Pour toi', true),
                    const Spacer(),
                    GestureDetector(
                        onTap: () => bientot(context),
                        child: const Icon(Icons.search, size: 28)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        barreBas(context),
      ]),
    );
  }
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
  bool favori = false;
  bool suivi = false;
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

  Widget action(IconData icon, String label, Color? color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
            onTap: onTap,
            child: Icon(icon, size: 34, color: color ?? Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          setState(() => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play()),
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
          right: 10,
          bottom: 20,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SizedBox(
                width: 56,
                height: 66,
                child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, size: 30)),
                      Positioned(
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => suivi = !suivi),
                          child: CircleAvatar(
                              radius: 11,
                              backgroundColor: bleu,
                              child: Icon(suivi ? Icons.check : Icons.add,
                                  size: 16, color: Colors.white)),
                        ),
                      ),
                    ]),
              ),
            ),
            action(
                liked ? Icons.favorite : Icons.favorite_border,
                '$likes',
                liked ? bleuClair : null,
                () => setState(() {
                      liked = !liked;
                      likes += liked ? 1 : -1;
                    })),
            action(Icons.chat_bubble_outline, '0', null,
                () => bientot(context)),
            action(
                favori ? Icons.bookmark : Icons.bookmark_border,
                'Favoris',
                favori ? bleuClair : null,
                () => setState(() => favori = !favori)),
            action(Icons.share, 'Partager', null, () => bientot(context)),
            GestureDetector(
              onTap: () => bientot(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                    border: Border.all(color: bleu, width: 3)),
                child: const Icon(Icons.music_note, size: 22),
              ),
            ),
          ]),
        ),
        const Positioned(
          left: 16,
          bottom: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@nom_createur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 6),
            Text('#flux #video', style: TextStyle(fontSize: 14)),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.search, size: 16),
              SizedBox(width: 4),
              Text('Recherche du son', style: TextStyle(fontSize: 13)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
