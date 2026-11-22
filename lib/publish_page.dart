import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const Color kBleu = Color(0xFF1E6BFF);

ColorFilter _sat(double s) {
  final r = 0.2126 * (1 - s);
  final g = 0.7152 * (1 - s);
  final b = 0.0722 * (1 - s);
  return ColorFilter.matrix(<double>[
    r + s, g, b, 0, 0,
    r, g + s, b, 0, 0,
    r, g, b + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

const List<String> kFiltres = [
  'aucun', 'noir et blanc', 'sepia', 'froid', 'chaud',
  'vif', 'doux', 'contraste', 'nuit',
];

ColorFilter filtreMatrice(String nom) {
  switch (nom) {
    case 'noir et blanc':
      return _sat(0);
    case 'sepia':
      return const ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case 'froid':
      return const ColorFilter.matrix(<double>[
        0.9, 0, 0, 0, 0,
        0, 1.0, 0, 0, 0,
        0, 0, 1.2, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case 'chaud':
      return const ColorFilter.matrix(<double>[
        1.2, 0, 0, 0, 0,
        0, 1.0, 0, 0, 0,
        0, 0, 0.8, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case 'vif':
      return _sat(1.6);
    case 'doux':
      return _sat(0.6);
    case 'contraste':
      return const ColorFilter.matrix(<double>[
        1.3, 0, 0, 0, -38,
        0, 1.3, 0, 0, -38,
        0, 0, 1.3, 0, -38,
        0, 0, 0, 1, 0,
      ]);
    case 'nuit':
      return const ColorFilter.matrix(<double>[
        0.6, 0, 0, 0, 0,
        0, 0.8, 0, 0, 0,
        0, 0, 1.3, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    default:
      return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
  }
}

const List<String> kTendances = [
  '#pourtoi', '#fyp', '#humour', '#danse', '#musique',
  '#sport', '#cuisine', '#voyage', '#astuce', '#afrique',
];

final RegExp _hashRe = RegExp(r'#[\p{L}0-9_]+', unicode: true);
final RegExp _mentRe = RegExp(r'@[\p{L}0-9_]+', unicode: true);

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});
  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _sb = Supabase.instance.client;
  final _desc = TextEditingController();
  final _lieu = TextEditingController();
  final _collab = TextEditingController();
  final _sousTitres = TextEditingController();
  final _epingle = TextEditingController();
  final _prix = TextEditingController();
  final AudioPlayer _audio = AudioPlayer();

  String? _videoPath;
  VideoPlayerController? _vc;
  String? _musicPath;
  String? _musicName;
  String? _coverPath;
  bool _audioPlaying = false;

  String _filtre = 'aucun';
  double _vitesse = 1;
  String _visibilite = 'public';
  bool _comments = true;
  bool _duo = true;
  bool _download = true;
  bool _ia = false;
  bool _payant = false;
  String _langue = 'fr';
  DateTime? _programme;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _audio.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _audioPlaying = false);
    });
  }

  @override
  void dispose() {
    _vc?.dispose();
    _audio.dispose();
    _desc.dispose();
    _lieu.dispose();
    _collab.dispose();
    _sousTitres.dispose();
    _epingle.dispose();
    _prix.dispose();
    super.dispose();
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _choisirVideo() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.video);
      if (r == null || r.files.isEmpty) return;
      final p = r.files.first.path;
      if (p == null) return;
      await _vc?.dispose();
      final c = VideoPlayerController.file(File(p));
      await c.initialize();
      await c.setLooping(true);
      await c.setPlaybackSpeed(_vitesse);
      await c.play();
      setState(() {
        _videoPath = p;
        _vc = c;
      });
    } catch (e) {
      _msg('Impossible de lire cette vidéo : $e');
    }
  }

  Future<void> _choisirSon() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    if (f.path == null) return;
    await _audio.stop();
    setState(() {
      _musicPath = f.path;
      _musicName = f.name;
      _audioPlaying = false;
    });
  }

  Future<void> _lireSon() async {
    if (_musicPath == null) return;
    if (_audioPlaying) {
      await _audio.stop();
    } else {
      await _audio.play(DeviceFileSource(_musicPath!));
    }
    setState(() => _audioPlaying = !_audioPlaying);
  }

  Future<void> _choisirCouverture() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r == null || r.files.isEmpty) return;
    setState(() => _coverPath = r.files.first.path);
  }

  Future<void> _changerVitesse(double v) async {
    setState(() => _vitesse = v);
    await _vc?.setPlaybackSpeed(v);
  }

  void _ajouterTag(String t) {
    final txt = _desc.text;
    _desc.text = (txt.isEmpty || txt.endsWith(' ')) ? '$txt$t ' : '$txt $t ';
    _desc.selection = TextSelection.collapsed(offset: _desc.text.length);
    setState(() {});
  }

  Future<void> _programmer() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (t == null) return;
    setState(() {
      _programme = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  String _extraire(RegExp re, String t) {
    return re
        .allMatches(t)
        .map((m) => m.group(0)!.toLowerCase())
        .toSet()
        .join(' ');
  }

  String _mime(String type, String ext) {
    if (type == 'video') return ext == 'mov' ? 'video/quicktime' : 'video/$ext';
    if (type == 'audio') {
      if (ext == 'mp3') return 'audio/mpeg';
      if (ext == 'm4a') return 'audio/mp4';
      return 'audio/$ext';
    }
    return ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
  }

  Future<String> _envoyer(String chemin, String dossier, String type) async {
    final uid = _sb.auth.currentUser!.id;
    final ext =
        chemin.contains('.') ? chemin.split('.').last.toLowerCase() : 'bin';
    final nom = '$uid/$dossier-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage.from('videos').upload(
          nom,
          File(chemin),
          fileOptions: FileOptions(contentType: _mime(type, ext)),
        );
    return _sb.storage.from('videos').getPublicUrl(nom);
  }

  Future<void> _publier({bool brouillon = false}) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      _msg("Connecte-toi d'abord.");
      return;
    }
    if (_videoPath == null) {
      _msg('Choisis une vidéo.');
      return;
    }
    setState(() => _busy = true);
    try {
      final videoUrl = await _envoyer(_videoPath!, 'video', 'video');
      String? musiqueUrl;
      if (_musicPath != null) {
        musiqueUrl = await _envoyer(_musicPath!, 'son', 'audio');
      }
      String? couvUrl;
      if (_coverPath != null) {
        couvUrl = await _envoyer(_coverPath!, 'cover', 'image');
      }
      final texte = _desc.text.trim();
      final prix = ((double.tryParse(_prix.text.replaceAll(',', '.')) ?? 0) *
              100)
          .round();
      await _sb.from('videos').insert({
        'user_id': user.id,
        'video_url': videoUrl,
        'description': texte,
        'hashtags': _extraire(_hashRe, texte),
        'mentions': _extraire(_mentRe, texte),
        'filter_name': _filtre,
        'speed': _vitesse,
        'music_title': _musicName ?? 'Son original',
        'music_url': musiqueUrl,
        'cover_url': couvUrl,
        'visibility': _visibilite,
        'allow_comments': _comments,
        'allow_duet': _duo,
        'allow_download': _download,
        'is_ai_generated': _ia,
        'is_draft': brouillon,
        'scheduled_at': _programme?.toUtc().toIso8601String(),
        'location': _lieu.text.trim().isEmpty ? null : _lieu.text.trim(),
        'language': _langue,
        'collab_username':
            _collab.text.trim().isEmpty ? null : _collab.text.trim(),
        'subtitles':
            _sousTitres.text.trim().isEmpty ? null : _sousTitres.text.trim(),
        'is_paid': _payant,
        'price_cents': _payant ? prix : 0,
        'pinned_comment':
            _epingle.text.trim().isEmpty ? null : _epingle.text.trim(),
      });
      if (!mounted) return;
      _msg(brouillon ? 'Brouillon enregistré' : 'Vidéo publiée !');
      Navigator.pop(context, true);
    } catch (e) {
      _msg('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: kBleu),
        ),
      );

  Widget _champ(TextEditingController c, String label,
      {int lignes = 1, TextInputType? clavier, void Function(String)? onCh}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: lignes,
        keyboardType: clavier,
        onChanged: onCh,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _interrupteur(String t, bool v, void Function(bool) f) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t),
      value: v,
      activeColor: kBleu,
      onChanged: f,
    );
  }

  Widget _apercu() {
    final c = _vc;
    if (c == null || !c.value.isInitialized) {
      return InkWell(
        onTap: _choisirVideo,
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0x141E6BFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBleu),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library, size: 48, color: kBleu),
                SizedBox(height: 8),
                Text('Choisir une vidéo (galerie ou Fichiers)'),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                });
              },
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: ColorFiltered(
                  colorFilter: filtreMatrice(_filtre),
                  child: VideoPlayer(c),
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _choisirVideo,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Changer de vidéo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = _extraire(_hashRe, _desc.text);
    final ments = _extraire(_mentRe, _desc.text);
    final p = _programme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier'),
        backgroundColor: kBleu,
        foregroundColor: Colors.white,
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            _apercu(),

            _titre('Filtres'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kFiltres
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filtre == f,
                            onSelected: (_) => setState(() => _filtre = f),
                          ),
                        ))
                    .toList(),
              ),
            ),

            _titre('Vitesse'),
            Wrap(
              spacing: 8,
              children: [0.5, 1.0, 1.5, 2.0]
                  .map((v) => ChoiceChip(
                        label: Text('${v}x'),
                        selected: _vitesse == v,
                        onSelected: (_) => _changerVitesse(v),
                      ))
                  .toList(),
            ),

            _titre('Description, #hashtags et @mentions'),
            _champ(_desc, 'Écris ta description...',
                lignes: 4, onCh: (_) => setState(() {})),
            Wrap(
              spacing: 6,
              children: kTendances
                  .map((t) => ActionChip(
                        label: Text(t),
                        onPressed: () => _ajouterTag(t),
                      ))
                  .toList(),
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Hashtags : $tags',
                    style: const TextStyle(color: kBleu)),
              ),
            if (ments.isNotEmpty)
              Text('Mentions : $ments', style: const TextStyle(color: kBleu)),

            _titre('Son'),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _musicName ?? 'Son original de la vidéo',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_musicPath != null)
                  IconButton(
                    onPressed: _lireSon,
                    icon: Icon(_audioPlaying ? Icons.stop : Icons.play_arrow,
                        color: kBleu),
                  ),
                TextButton(
                    onPressed: _choisirSon, child: const Text('Choisir un son')),
              ],
            ),

            _titre('Couverture'),
            Row(
              children: [
                Expanded(
                  child: Text(_coverPath == null
                      ? 'Aucune (image automatique)'
                      : 'Image choisie'),
                ),
                TextButton(
                    onPressed: _choisirCouverture,
                    child: const Text('Choisir une image')),
              ],
            ),

            _titre('Qui peut voir cette vidéo ?'),
            Wrap(
              spacing: 8,
              children: [
                ['public', 'Tout le monde'],
                ['amis', 'Amis'],
                ['prive', 'Moi seul'],
              ]
                  .map((v) => ChoiceChip(
                        label: Text(v[1]),
                        selected: _visibilite == v[0],
                        onSelected: (_) => setState(() => _visibilite = v[0]),
                      ))
                  .toList(),
            ),

            _titre('Autorisations'),
            _interrupteur('Autoriser les commentaires', _comments,
                (v) => setState(() => _comments = v)),
            _interrupteur('Autoriser les duos', _duo,
                (v) => setState(() => _duo = v)),
            _interrupteur('Autoriser le téléchargement', _download,
                (v) => setState(() => _download = v)),
            _interrupteur('Contenu généré par IA', _ia,
                (v) => setState(() => _ia = v)),

            _titre('Options avancées'),
            _champ(_lieu, 'Lieu (ville, pays)'),
            _champ(_collab, 'Collaboration avec (nom du créateur)'),
            _champ(_sousTitres, 'Sous-titres (texte)', lignes: 3),
            _champ(_epingle, 'Commentaire épinglé'),
            DropdownButtonFormField<String>(
              value: _langue,
              decoration: const InputDecoration(
                labelText: 'Langue de la vidéo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
              ],
              onChanged: (v) => setState(() => _langue = v ?? 'fr'),
            ),

            _titre('Publication programmée'),
            Row(
              children: [
                Expanded(
                  child: Text(p == null
                      ? 'Publier maintenant'
                      : 'Le ${p.day}/${p.month}/${p.year} à ${p.hour}h${p.minute.toString().padLeft(2, '0')}'),
                ),
                TextButton(
                    onPressed: _programmer, child: const Text('Programmer')),
                if (p != null)
                  IconButton(
                    onPressed: () => setState(() => _programme = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),

            _titre('Monétisation'),
            _interrupteur('Vidéo payante (contenu exclusif)', _payant,
                (v) => setState(() => _payant = v)),
            if (_payant)
              _champ(_prix, 'Prix (ex : 2.50)',
                  clavier: const TextInputType.numberWithOptions(decimal: true)),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _busy ? null : () => _publier(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBleu,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Publier', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _busy ? null : () => _publier(brouillon: true),
                child: const Text('Enregistrer en brouillon'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
