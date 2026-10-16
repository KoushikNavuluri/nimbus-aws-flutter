import 'package:flutter/material.dart';

import '../art/art.dart';
import '../data/services.dart';
import '../nav.dart';
import '../sound.dart';
import '../store.dart';
import '../theme.dart';
import '../ui/holo_card.dart';
import '../ui/kit.dart';
import '../ui/motion.dart';
import 'common.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});
  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  String _f = 'all';
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = watch(context).state;
    final owned = s.collected.length;
    final holo = s.collected.values.where((c) => c.level == 2).length;
    final q = _q.text.trim().toLowerCase();
    final list = kServices.where((x) {
      if (_f == 'fav' && !s.favorites.contains(x.id)) return false;
      if (_f != 'all' && _f != 'fav' && x.type != _f) return false;
      if (q.isNotEmpty) {
        final known = s.collected.containsKey(x.id);
        final hay = [x.name, known ? x.nick : '', ...(kAliases[x.id] ?? const <String>[])].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    final filters = <(String, String)>[('all', 'All'), ('fav', 'Favorites'), for (final e in kTypes.entries) (e.key, e.value.label)];

    return ListView(
      padding: EdgeInsets.only(bottom: Insets.bottomOf(context) + 100),
      children: [
        TabTitle(
          title: 'The Cloudex.',
          sub: '$owned of ${kServices.length} found · $holo holo',
          child: Column(
            children: [
              const SizedBox(height: 12),
              PBar(pct: owned / kServices.length, h: 10, gradient: const LinearGradient(colors: [C.flamingo, C.grape, C.blue])),
              const SizedBox(height: 12),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line, width: 1.5)),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 20, color: C.ink3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        style: tUi(16),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration.collapsed(hintText: 'Search: queue, dns, bucket…', hintStyle: tUi(16, color: C.ink3)),
                      ),
                    ),
                    if (_q.text.isNotEmpty)
                      Press(
                        label: 'Clear search',
                        onTap: () {
                          _q.clear();
                          setState(() {});
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: C.sky, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 17, color: C.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filters.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              final k = filters[i].$1;
              final on = _f == k;
              final type = kTypes[k];
              Widget? leading;
              if (k == 'fav') {
                leading = Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded);
              } else if (type != null) {
                leading = Container(width: 10, height: 10, decoration: BoxDecoration(color: type.color, shape: BoxShape.circle));
              }
              return Center(child: NChip(label: filters[i].$2, on: on, leading: leading, onTap: () => setState(() => _f = k)));
            },
          ),
        ),
        if (list.isEmpty)
          EmptyState(
            art: const Puff(size: 120, mood: 'think'),
            title: _f == 'fav' ? 'No favorites yet' : 'Nothing matches',
            body: _f == 'fav' ? 'Tap the heart on any card to keep it close.' : 'Try another word, like "storage" or "queue".',
            action: NBtn(
              label: 'Show everything',
              kind: Btn.soft,
              onTap: () {
                _q.clear();
                setState(() => _f = 'all');
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: [
                for (var i = 0; i < list.length; i++)
                  Rise(
                    key: ValueKey('${_f}_${list[i].id}'),
                    index: i < 10 ? i : 10,
                    step: 30,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        HoloCard(
                          id: list[i].id,
                          size: 'md',
                          silhouette: !s.collected.containsKey(list[i].id),
                          tilt: s.collected.containsKey(list[i].id),
                          idle: false,
                          onTap: () {
                            Sfx.play('pop');
                            Nav.overlay('card', id: list[i].id);
                          },
                        ),
                        if (s.favorites.contains(list[i].id))
                          Positioned(
                            top: -6,
                            right: -6,
                            child: IgnorePointer(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 2)),
                                child: const Icon(Icons.favorite_rounded, size: 14, color: C.flamingo),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
