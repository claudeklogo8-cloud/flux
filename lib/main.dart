import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'publish_page.dart';
import 'video_viewer.dart';

const supabaseUrl = 'https://pvkmzpremfxhrygqcgqz.supabase.co';
const supabaseKey = 'sb_publishable_28Yec-iC2QtoYcj5vY0WpQ_MkcPH2h7';
const bleu = Color(0xFF1E88E5);
const bleuClair = Color(0xFF42A5F5);

SupabaseClient get db => Supabase.instance.client;
String get uid => db.auth.currentUser!.id;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const FluxApp());
}

void msg(BuildContext c, String t) {
  ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(t), duration: const Duration(seconds: 2)));
}

void bientot(BuildContext c) => msg(c, 'Bientôt disponible');

Future<String?> demanderTexte(BuildContext c) {
  final t = TextEditingController();
  return showDialog<String>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: const Text('Description'),
      content: TextField(
          controller: t,
          decoration: const InputDecoration(
              hintText: 'Ex : mon premier #flux')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, t.text),
            child: const Text('Publier')),
      ],
    ),
  );
}

void profil(BuildContext c) { Navigator.push(c, MaterialPageRoute(builder: (_) => const ProfilePage())); return;
  final mail = db.auth.currentUser?.email ?? '';
  showModalBottomSheet(
    context: c,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person, size: 48),
        const SizedBox(height: 8),
        Text(mail),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await db.auth.signOut();
          },
          child: const Text('Se déconnecter'),
        ),
      ]),
    ),
  );
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

Widget navItem(IconData icon, String label, bool actif, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
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

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'flux',
        theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: bleu)),
        home: StreamBuilder<AuthState>(
          stream: db.auth.onAuthStateChange,
          builder: (context, snap) => db.auth.currentSession == null
              ? const AuthPage()
              : const Shell(),
        ),
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final mail = TextEditingController();
  final mdp = TextEditingController();
  final nom = TextEditingController();
  bool inscription = false;
  bool charge = false;

  Future<void> valider() async {
    if (inscription && nom.text.trim().length < 3) {
      msg(context, 'Choisis un nom d’utilisateur (3 lettres minimum)');
      return;
    }
    setState(() => charge = true);
    try {
      if (inscription) {
        final r = await db.auth.signUp(
            email: mail.text.trim(),
            password: mdp.text,
            data: {'username': nom.text.trim()});
        if (r.session == null && mounted) {
          msg(context, 'Compte créé. Confirme ton e-mail puis connecte-toi.');
        }
      } else {
        await db.auth
            .signInWithPassword(email: mail.text.trim(), password: mdp.text);
      }
    } on AuthException catch (e) {
      if (mounted) msg(context, e.message);
    } catch (e) {
      if (mounted) msg(context, 'Erreur : $e');
    }
    if (mounted) setState(() => charge = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Text('flux',
                  style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: bleuClair)),
              const SizedBox(height: 4),
              const Text('Partage tes vidéos avec le monde'),
              const SizedBox(height: 28),
              if (inscription) ...[
                TextField(
                    controller: nom,
                    decoration: const InputDecoration(
                        labelText: 'Nom d’utilisateur',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
              ],
              TextField(
                  controller: mail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: mdp,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Mot de passe (6 caractères minimum)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: charge ? null : valider,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: bleu,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(inscription ? 'Créer mon compte' : 'Se connecter'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => inscription = !inscription),
                child: Text(inscription
                    ? 'J’ai déjà un compte'
                    : 'Pas de compte ? S’inscrire'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  List<Map<String, dynamic>> videos = [];
  bool charge = true;
  bool envoi = false;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    if (mounted) setState(() => charge = true);
    try {
      final r = await db
          .from('videos_feed')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      videos = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      videos = [];
    }
    if (mounted) setState(() => charge = false);
  }

  Future<void> publier() async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishPage()));
    if (mounted) setState(() {});
    return;
    if (envoi) return;
    final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (f == null || !mounted) return;
    final taille = await f.length();
    if (taille > 50 * 1024 * 1024) {
      if (mounted) msg(context, 'Vidéo trop lourde (50 Mo maximum)');
      return;
    }
    if (!mounted) return;
    final desc = await demanderTexte(context);
    if (desc == null || !mounted) return;
    setState(() => envoi = true);
    try {
      final chemin = '$uid/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await db.storage.from('videos').upload(chemin, File(f.path),
          fileOptions: const FileOptions(contentType: 'video/mp4'));
      final url = db.storage.from('videos').getPublicUrl(chemin);
      await db.from('videos').insert(
          {'user_id': uid, 'video_url': url, 'description': desc.trim()});
      if (mounted) msg(context, 'Vidéo publiée !');
      await charger();
    } catch (e) {
      if (mounted) msg(context, 'Erreur d’envoi : $e');
    }
    if (mounted) setState(() => envoi = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget corps;
    if (charge) {
      corps = const Center(child: CircularProgressIndicator());
    } else if (videos.isEmpty) {
      corps = const Center(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                  'Aucune vidéo pour le moment.\nAppuie sur Créer pour publier la première !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16))));
    } else {
      corps = PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (_, i) =>
            VideoPage(key: ValueKey(videos[i]['id']), v: videos[i]),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            corps,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                  if (envoi) const LinearProgressIndicator(),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          color: Colors.black,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    navItem(Icons.person_outline, 'Profil', false,
                        () => profil(context)),
                    navItem(Icons.group_outlined, 'Amis', false,
                        () => bientot(context)),
                    GestureDetector(
                      onTap: publier,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                            color: bleu,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Créer',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    navItem(Icons.mail_outline, 'Message', false,
                        () => bientot(context)),
                    navItem(Icons.home, 'Accueil', true, charger),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class VideoPage extends StatefulWidget {
  final Map<String, dynamic> v;
  const VideoPage({super.key, required this.v});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController ctrl;
  bool liked = false;
  bool favori = false;
  bool suivi = false;
  int nbLikes = 0;
  int nbComm = 0;

  String get id => '${widget.v['id']}';
  String get auteur => '${widget.v['user_id']}';

  @override
  void initState() {
    super.initState();
    nbLikes = int.tryParse('${widget.v['likes_count']}') ?? 0;
    nbComm = int.tryParse('${widget.v['comments_count']}') ?? 0;
    ctrl = VideoPlayerController.networkUrl(
        Uri.parse('${widget.v['video_url']}'))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          ctrl.play();
        }
      });
    etat();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> etat() async {
    try {
      final l = await db
          .from('likes')
          .select('video_id')
          .eq('video_id', id)
          .eq('user_id', uid);
      final f = await db
          .from('favorites')
          .select('video_id')
          .eq('video_id', id)
          .eq('user_id', uid);
      final s = await db
          .from('follows')
          .select('following_id')
          .eq('following_id', auteur)
          .eq('follower_id', uid);
      if (!mounted) return;
      setState(() {
        liked = l.isNotEmpty;
        favori = f.isNotEmpty;
        suivi = s.isNotEmpty;
      });
    } catch (_) {}
  }

  Future<void> basculerLike() async {
    final etait = liked;
    setState(() {
      liked = !etait;
      nbLikes += etait ? -1 : 1;
    });
    try {
      if (etait) {
        await db.from('likes').delete().eq('video_id', id).eq('user_id', uid);
      } else {
        await db.from('likes').insert({'video_id': id, 'user_id': uid});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          liked = etait;
          nbLikes += etait ? 1 : -1;
        });
      }
    }
  }

  Future<void> basculerFavori() async {
    final etait = favori;
    setState(() => favori = !etait);
    try {
      if (etait) {
        await db
            .from('favorites')
            .delete()
            .eq('video_id', id)
            .eq('user_id', uid);
      } else {
        await db.from('favorites').insert({'video_id': id, 'user_id': uid});
      }
    } catch (_) {
      if (mounted) setState(() => favori = etait);
    }
  }

  Future<void> basculerSuivi() async {
    final etait = suivi;
    setState(() => suivi = !etait);
    try {
      if (etait) {
        await db
            .from('follows')
            .delete()
            .eq('following_id', auteur)
            .eq('follower_id', uid);
      } else {
        await db
            .from('follows')
            .insert({'follower_id': uid, 'following_id': auteur});
      }
    } catch (_) {
      if (mounted) setState(() => suivi = etait);
    }
  }

  Future<void> signaler() async {
    try {
      await db
          .from('reports')
          .insert({'video_id': id, 'user_id': uid, 'reason': 'signalement'});
      if (mounted) msg(context, 'Merci, la vidéo a été signalée');
    } catch (_) {
      if (mounted) msg(context, 'Impossible de signaler');
    }
  }

  void commentaires() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(
          videoId: id,
          onAjout: () {
            if (mounted) setState(() => nbComm += 1);
          }),
    );
  }

  Widget action(IconData icon, String label, Color? color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
            onTap: onTap,
            child: Icon(icon, size: 30, color: color ?? Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moi = auteur == uid;
    final nom = '${widget.v['username']}';
    final desc = '${widget.v['description'] ?? ''}';
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
          bottom: 12,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
                      if (!moi)
                        Positioned(
                          bottom: 0,
                          child: GestureDetector(
                            onTap: basculerSuivi,
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
            action(liked ? Icons.favorite : Icons.favorite_border, '$nbLikes',
                liked ? bleuClair : null, basculerLike),
            action(Icons.chat_bubble_outline, '$nbComm', null, commentaires),
            action(favori ? Icons.bookmark : Icons.bookmark_border, 'Favoris',
                favori ? bleuClair : null, basculerFavori),
            action(Icons.share, 'Partager', null, () async {
              await Clipboard.setData(
                  ClipboardData(text: '${widget.v['video_url']}'));
              if (mounted) msg(context, 'Lien copié');
            }),
            action(Icons.flag_outlined, 'Signaler', null, signaler),
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
        Positioned(
          left: 16,
          right: 90,
          bottom: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@$nom',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            const Row(children: [
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

class CommentsSheet extends StatefulWidget {
  final String videoId;
  final VoidCallback onAjout;
  const CommentsSheet({super.key, required this.videoId, required this.onAjout});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final t = TextEditingController();
  List<Map<String, dynamic>> liste = [];
  bool charge = true;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    try {
      final r = await db
          .from('comments')
          .select('content, created_at, profiles(username)')
          .eq('video_id', widget.videoId)
          .order('created_at', ascending: false);
      liste = List<Map<String, dynamic>>.from(r);
    } catch (_) {
      liste = [];
    }
    if (mounted) setState(() => charge = false);
  }

  Future<void> envoyer() async {
    final texte = t.text.trim();
    if (texte.isEmpty) return;
    t.clear();
    try {
      await db.from('comments').insert(
          {'video_id': widget.videoId, 'user_id': uid, 'content': texte});
      widget.onAjout();
      await charger();
    } catch (_) {
      if (mounted) msg(context, 'Impossible de commenter');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 420,
        child: Column(children: [
          const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Commentaires',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(
            child: charge
                ? const Center(child: CircularProgressIndicator())
                : liste.isEmpty
                    ? const Center(child: Text('Sois le premier à commenter'))
                    : ListView.builder(
                        itemCount: liste.length,
                        itemBuilder: (_, i) {
                          final p = liste[i]['profiles'];
                          final nom = p is Map ? '${p['username']}' : 'utilisateur';
                          return ListTile(
                            dense: true,
                            title: Text('@$nom',
                                style: const TextStyle(
                                    fontSize: 13, color: bleuClair)),
                            subtitle: Text('${liste[i]['content']}'),
                          );
                        }),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: t,
                      decoration: const InputDecoration(
                          hintText: 'Ajouter un commentaire',
                          border: OutlineInputBorder(),
                          isDense: true))),
              IconButton(
                  icon: const Icon(Icons.send, color: bleuClair),
                  onPressed: envoyer),
            ]),
          ),
        ]),
      ),
    );
  }
}
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
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _videos = [];
  int _following = 0, _followers = 0, _likes = 0;
  bool _loading = true;
  Future<void> _changePhoto() async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (f == null) return;
    try {
      final chemin = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await db.storage.from('videos').upload(chemin, File(f.path),
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final url = db.storage.from('videos').getPublicUrl(chemin);
      await db.from('profiles').update({'avatar_url': url}).eq('id', uid);
      await _load();
      if (mounted) msg(context, 'Photo mise à jour');
    } catch (e) {
      if (mounted) msg(context, 'Erreur : $e');
    }
  }
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _count(String col) async {
    try {
      final r = await db.from('follows').select().eq(col, uid);
      return (r as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _load() async {
    try {
      _profile =
          await db.from('profiles').select().eq('id', uid).maybeSingle();
    } catch (_) {}
    List<Map<String, dynamic>> vids = [];
    int likes = 0;
    try {
      final r = await db
          .from('videos_feed')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      vids = List<Map<String, dynamic>>.from(r);
      for (final v in vids) {
        likes += int.tryParse('${v['likes_count']}') ?? 0;
      }
    } catch (_) {}
    final following = await _count('follower_id');
    final followers = await _count('following_id');
    if (!mounted) return;
    setState(() {
      _videos = vids;
      _likes = likes;
      _following = following;
      _followers = followers;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final bio = TextEditingController(text: '${_profile?['bio'] ?? ''}');
    final link = TextEditingController(text: '${_profile?['link'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: bio,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Biographie')),
          TextField(
              controller: link,
              decoration: const InputDecoration(labelText: 'Lien')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await db.from('profiles').update(
          {'bio': bio.text.trim(), 'link': link.text.trim()}).eq('id', uid);
      await _load();
    } catch (e) {
      if (mounted) msg(context, 'Erreur : $e');
    }
  }

  void _menu() {
      Future<void> _changePhoto() async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (f == null) return;
    try {
      final chemin = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await db.storage.from('videos').upload(chemin, File(f.path),
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final url = db.storage.from('videos').getPublicUrl(chemin);
      await db.from('profiles').update({'avatar_url': url}).eq('id', uid);
      await _load();
      if (mounted) msg(context, 'Photo mise à jour');
    } catch (e) {
      if (mounted) msg(context, 'Erreur : $e');
    }
      } 
                  void _menuComplet() {
    Widget item(IconData icon, String titre, VoidCallback onTap) => ListTile(
          leading: Icon(icon),
          title: Text(titre),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: ListView(shrinkWrap: true, children: [
            item(Icons.edit_outlined, 'Modifier le profil', () {
              Navigator.pop(c);
              _edit();
            }),
                        item(Icons.photo_camera_outlined, 'Changer la photo de profil', () {
              Navigator.pop(c);
              _changePhoto();
            }),
            item(Icons.bookmark_border, 'Mes favoris', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.favorite_border, 'Mes likes', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.history, 'Historique de visionnage', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.download_outlined, 'Vidéos hors ligne', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.share_outlined, 'Partager le profil', () async {
              Navigator.pop(c);
              await Clipboard.setData(
                  ClipboardData(text: '@${_profile?['username'] ?? ''}'));
              if (mounted) msg(context, 'Pseudo copié');
            }),
            const Divider(height: 1),
            item(Icons.notifications_none, 'Notifications', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.lock_outline, 'Confidentialité et sécurité', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.language, 'Langue', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.help_outline, 'Aide et assistance', () {
              Navigator.pop(c);
              bientot(context);
            }),
            item(Icons.info_outline, 'À propos de flux', () {
              Navigator.pop(c);
              bientot(context);
            }),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                final nav = Navigator.of(context);
                Navigator.pop(c);
                await db.auth.signOut();
                nav.popUntil((r) => r.isFirst);
              },
            ),
          ]),
        ),
      ),
    );
                  }
        _menuComplet(); return;
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier le profil'),
            onTap: () {
              Navigator.pop(c);
              _edit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              final nav = Navigator.of(context);
              Navigator.pop(c);
              await db.auth.signOut();
              nav.popUntil((r) => r.isFirst);
            },
          ),
        ]),
      ),
    );
  }

  Widget _stat(int n, String label) => Column(children: [
        Text('$n',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]);

  @override
  Widget build(BuildContext context) {
    final name = '${_profile?['username'] ?? 'Mon profil'}';
    final avatar = '${_profile?['avatar_url'] ?? ''}';
    final bio = _profile?['bio'] == null ? '' : '${_profile!['bio']}';
    final link = _profile?['link'] == null ? '' : '${_profile!['link']}';
    return Scaffold(
      appBar: AppBar(
        title: Text('@$name'),
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: _menu)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(children: [
                const SizedBox(height: 16),
                Center(
                  child: Stack(children: [CircleAvatar(
                    radius: 48,
                    backgroundColor: bleu,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 36, color: Colors.white))
                        : null,
                  ),
                                                            Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _changePhoto,
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: bleuClair,
                        child:
                            Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
                ),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat(_following, 'Abonnements'),
                      _stat(_followers, 'Abonnés'),
                      _stat(_likes, 'Likes reçus'),
                    ]),
                if (bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(bio, textAlign: TextAlign.center),
                  ),
                if (link.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(link,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: bleuClair)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                      onPressed: _edit,
                      child: const Text('Modifier le profil')),
                ),
                const Divider(height: 1),
                if (_videos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aucune vidéo publiée')),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                        onTap: () => Navigator.push(
                            c,
                            MaterialPageRoute(
                                builder: (_) =>
                                    VideoViewer(videos: _videos, index: i))),
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
              ]),
            ),
    );
  }
}
