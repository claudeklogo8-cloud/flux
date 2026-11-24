import 'package:flutter/material.dart';
import 'package:flux/main.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _notifs = [];
  Map<String, Map<String, dynamic>> _profils = {};
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await db
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      final liste = List<Map<String, dynamic>>.from(r);
      final ids = liste
          .map((n) => n['actor_id'])
          .where((a) => a != null)
          .toSet()
          .toList();
      final profils = <String, Map<String, dynamic>>{};
      if (ids.isNotEmpty) {
        final p = await db.from('profiles').select().inFilter('id', ids);
        for (final x in List<Map<String, dynamic>>.from(p)) {
          profils['${x['id']}'] = x;
        }
      }
      if (!mounted) return;
      setState(() {
        _notifs = liste;
        _profils = profils;
        _chargement = false;
      });
      await db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
      msg(context, 'Impossible de charger : $e');
    }
  }

  String _temps(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'à l’instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }

  String _texte(Map<String, dynamic> n) {
    switch (n['type']) {
      case 'like':
        return 'a aimé ta vidéo';
      case 'comment':
        return 'a commenté : ${n['content'] ?? ''}';
      case 'follow':
        return 's’est abonné à toi';
      case 'message':
        return 't’a envoyé un message';
      default:
        return '${n['content'] ?? ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), centerTitle: true),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: _notifs.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Aucune notification pour le moment')),
                    ])
                  : ListView.builder(
                      itemCount: _notifs.length,
                      itemBuilder: (c, i) {
                        final n = _notifs[i];
                        final p = _profils['${n['actor_id']}'];
                        final nom = p == null
                            ? 'flux'
                            : '${p['username'] ?? 'utilisateur'}';
                        final avatar =
                            p == null ? '' : '${p['avatar_url'] ?? ''}';
                        final aPhoto = avatar.isNotEmpty && avatar != 'null';
                        final nonLu = n['is_read'] != true;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bleu,
                            backgroundImage:
                                aPhoto ? NetworkImage(avatar) : null,
                            child: aPhoto
                                ? null
                                : Text(
                                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                    style:
                                        const TextStyle(color: Colors.white)),
                          ),
                          title: Text('@$nom',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${_texte(n)} · ${_temps('${n['created_at']}')}'),
                          trailing: nonLu
                              ? const CircleAvatar(
                                  radius: 5, backgroundColor: Colors.redAccent)
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}
