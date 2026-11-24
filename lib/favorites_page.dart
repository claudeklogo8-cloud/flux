import 'package:flutter/material.dart';
import 'package:flux/main.dart';
import 'package:flux/video_viewer.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _videos = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final f =
          await db.from('favorites').select('video_id').eq('user_id', uid);
      final ids = List<Map<String, dynamic>>.from(f)
          .map((x) => x['video_id'])
          .toList();
      List<Map<String, dynamic>> videos = [];
      if (ids.isNotEmpty) {
        final r = await db
            .from('videos_feed')
            .select()
            .inFilter('id', ids)
            .order('created_at', ascending: false);
        videos = List<Map<String, dynamic>>.from(r);
      }
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
      msg(context, 'Impossible de charger : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris'), centerTitle: true),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: _videos.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Aucun favori pour le moment.\nAppuie sur « Favoris » sous une vidéo pour l’ajouter ici.',
                            textAlign: TextAlign.center),
                      )),
                    ])
                  : GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              childAspectRatio: 0.7),
                      itemCount: _videos.length,
                      itemBuilder: (c, i) {
                        final cover = '${_videos[i]['cover_url'] ?? ''}';
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                                c,
                                MaterialPageRoute(
                                    builder: (_) => VideoViewer(
                                        videos: _videos, index: i)));
                            _charger();
                          },
                          child: Container(
                            color: const Color(0xFF0D2A4A),
                            child: Stack(fit: StackFit.expand, children: [
                              if (cover.isNotEmpty && cover != 'null')
                                Image.network(cover,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const SizedBox()),
                              const Center(
                                  child: Icon(Icons.play_arrow,
                                      color: Colors.white70, size: 36)),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
