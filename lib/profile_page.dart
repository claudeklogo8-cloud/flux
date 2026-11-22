import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'publish_page.dart' show filtreMatrice;

const Color _bleu = Color(0xFF1E88E5);
const Color _bleuFonce = Color(0xFF0D2A57);

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _db = Supabase.instance.client;
  final _cle = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _profil;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _favoris = [];
  int _abonnements = 0;
  int _abonnes = 0;
  int _likes = 0;
  bool _charge = false;
  bool _jeSuis = false;
  int _onglet = 0;

  String get _monId => _db.auth.currentUser?.id ?? '';
  String get _id => widget.userId ?? _monId;
  bool get _moi => _id == _monId;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _charger() async {
    if (_id.isEmpty) {
      setState(() => _charge = true);
      return;
    }
    try {
      final p = await _db.from('profiles').select().eq('id', _id).maybeSingle();
      var q = _db.from('videos').select().eq('user_id', _id);
      if (!_moi) {
        q = q.eq('is_draft', false).eq('visibility', 'public');
      }
      final v = await q.order('created_at', ascending: false);
      final ab = await _db
          .from('follows')
          .select('following_id')
          .eq('follower_id', _id);
      final fo = await _db
          .from('follows')
          .select('follower_id')
          .eq('following_id', _id);
      int likes = 0;
      final ids = (v as List).map((e) => e['id']).toList();
      if (ids.isNotEmpty) {
        final l = await _db.from('likes').select('video_id').inFilter('video_id', ids);
        likes = (l as List).length;
      }
      bool suit = false;
      if (!_moi && _monId.isNotEmpty) {
        final s = await _db
            .from('follows')
            .select()
            .eq('follower_id', _monId)
            .eq('following_id', _id)
            .maybeSingle();
        suit = s != null;
      }
      List<Map<String, dynamic>> fav = [];
      if (_moi) {
        final f = await _db.from('favorites').select('video_id').eq('user_id', _id);
        final fids = (f as List).map((e) => e['video_id']).toList();
        if (fids.isNotEmpty) {
          final fv = await _db.from('videos').select().inFilter('id', fids);
          fav = List<Map<String, dynamic>>.from(fv as List);
        }
      }
      if (!mounted) return;
      setState(() {
        _profil = p;
        _videos = List<Map<String, dynamic>>.from(v);
        _favoris = fav;
        _abonnements = (ab as List).length;
        _abonnes = (fo as List).length;
        _likes = likes;
        _jeSuis = suit;
        _charge = true;
      });
    } catch (e) {
      _msg('Erreur : $e');
      if (mounted) setState(() => _charge = true);
    }
  }

  Future<void> _suivre() async {
    if (_monId.isEmpty) {
      _msg("Connecte-toi d'abord.");
      return;
    }
    try {
      if (_jeSuis) {
        await _db
            .from('follows')
            .delete()
            .eq('follower_id', _monId)
            .eq('following_id', _id);
      } else {
        await _db
            .from('follows')
            .insert({'follower_id': _monId, 'following_id': _id});
      }
      setState(() {
        _jeSuis = !_jeSuis;
        _abonnes += _jeSuis ? 1 : -1;
      });
    } catch (e) {
      _msg('Erreur : $e');
    }
  }

  Future<String?> _envoyerAvatar() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (f == null) return null;
    final ext =
        f.path.contains('.') ? f.path.split('.').last.toLowerCase() : 'jpg';
    final nom = '$_monId/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('videos').upload(
          nom,
          File(f.path),
          fileOptions: FileOptions(
              contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext'),
        );
    return _db.storage.from('videos').getPublicUrl(nom);
  }

  Future<void> _modifier() async {
    final nom = TextEditingController(text: (_profil?['display_name'] ?? '') as String);
    final bio = TextEditingController(text: (_profil?['bio'] ?? '') as String);
    final lien = TextEditingController(text: (_profil?['website'] ?? '') as String);
    String? avatar = _profil?['avatar_url'] as String?;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final u = await _envoyerAvatar();
                      if (u != null) setD(() => avatar = u);
                    } catch (e) {
                      _msg('Erreur : $e');
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: _bleu,
                    backgroundImage: (avatar != null && avatar!.isNotEmpty)
                        ? NetworkImage(avatar!)
                        : null,
                    child: (avatar == null || avatar!.isEmpty)
                        ? const Icon(Icons.add_a_photo, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Appuie pour changer la photo',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: nom,
                  decoration: const InputDecoration(
                      labelText: 'Nom affiché', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bio,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                      labelText: 'Biographie', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: lien,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      labelText: 'Lien', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await _db.from('profiles').update({
          'display_name': nom.text.trim(),
          'bio': bio.text.trim(),
          'website': lien.text.trim(),
          'avatar_url': avatar,
        }).eq('id', _monId);
        await _charger();
      } catch (e) {
        _msg('Erreur : $e');
      }
    }
  }

  Future<void> _deconnexion() async {
    await _db.auth.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _stat(int n, String label) {
    return Column(
      children: [
        Text('$n',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _entete() {
    final nom = ((_profil?['display_name'] ?? '') as String).trim();
    final pseudo = (_profil?['username'] ?? '') as String;
    final bio = (_profil?['bio'] ?? '') as String;
    final lien = (_profil?['website'] ?? '') as String;
    final avatar = _profil?['avatar_url'] as String?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: _bleu,
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 10),
          Text(nom.isNotEmpty ? nom : '@$pseudo',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (nom.isNotEmpty && pseudo.isNotEmpty)
            Text('@$pseudo', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(_abonnements, 'Abonnements'),
              _stat(_abonnes, 'Abonnés'),
              _stat(_likes, 'Likes reçus'),
            ],
          ),
          const SizedBox(height: 14),
          if (_moi)
            OutlinedButton.icon(
              onPressed: _modifier,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier le profil'),
            )
          else
            ElevatedButton(
              onPressed: _suivre,
              style: ElevatedButton.styleFrom(
                backgroundColor: _jeSuis ? Colors.grey.shade300 : _bleu,
                foregroundColor: _jeSuis ? Colors.black : Colors.white,
                minimumSize: const Size(180, 42),
              ),
              child: Text(_jeSuis ? 'Abonné' : "S'abonner"),
            ),
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(bio, textAlign: TextAlign.center),
            ),
          if (lien.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: lien));
                  _msg('Lien copié');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link, size: 18, color: _bleu),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(lien,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _bleu, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _onglets() {
    Widget bouton(int i, IconData ic) {
      final actif = _onglet == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _onglet = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: actif ? _bleu : Colors.transparent, width: 2),
              ),
            ),
            child: Icon(ic, color: actif ? _bleu : Colors.grey),
          ),
        ),
      );
    }

    return Row(
      children: [
        bouton(0, Icons.grid_on),
        if (_moi) bouton(1, Icons.favorite_border),
      ],
    );
  }

  Widget _vignette(Map<String, dynamic> v) {
    final d = (v['description'] ?? '') as String;
    return Container(
      color: _bleuFonce,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(d,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _grille(List<Map<String, dynamic>> l) {
    if (l.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Aucune vidéo pour le moment')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: l.length,
      itemBuilder: (c, i) {
        final v = l[i];
        final cov = v['cover_url'] as String?;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _LecteurPage(
                url: v['video_url'] as String,
                filtre: (v['filter_name'] ?? 'aucun') as String,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (cov != null && cov.isNotEmpty)
                  ? Image.network(cov,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _vignette(v))
                  : _vignette(v),
              if (v['is_draft'] == true)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black54,
                    child: const Text('Brouillon',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _menu() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Menu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            if (_moi)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier le profil'),
                onTap: () {
                  Navigator.pop(context);
                  _modifier();
                },
              ),
            if (_moi)
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Mes favoris'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _onglet = 1);
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Copier le nom du profil'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                    ClipboardData(text: '@${_profil?['username'] ?? ''}'));
                _msg('Copié');
              },
            ),
            if (_moi)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Se déconnecter'),
                onTap: () {
                  Navigator.pop(context);
                  _deconnexion();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pseudo = (_profil?['username'] ?? 'Profil') as String;
    return Scaffold(
      key: _cle,
      appBar: AppBar(
        title: Text(pseudo),
        backgroundColor: _bleu,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _cle.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _menu(),
      body: !_charge
          ? const Center(child: CircularProgressIndicator())
          : _id.isEmpty
              ? const Center(child: Text('Connecte-toi pour voir ton profil'))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    children: [
                      _entete(),
                      _onglets(),
                      _grille(_onglet == 0 ? _videos : _favoris),
                    ],
                  ),
                ),
    );
  }
}

class _LecteurPage extends StatefulWidget {
  final String url;
  final String filtre;
  const _LecteurPage({required this.url, required this.filtre});
  @override
  State<_LecteurPage> createState() => _LecteurPageState();
}

class _LecteurPageState extends State<_LecteurPage> {
  late final VideoPlayerController _c;
  bool _pret = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c.initialize().then((_) {
      _c.setLooping(true);
      _c.play();
      if (mounted) setState(() => _pret = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _pret
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _c.value.isPlaying ? _c.pause() : _c.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _c.value.aspectRatio,
                  child: ColorFiltered(
                    colorFilter: filtreMatrice(widget.filtre),
                    child: VideoPlayer(_c),
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
