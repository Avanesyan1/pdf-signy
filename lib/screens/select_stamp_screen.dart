import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart' as db;

@RoutePage()
class SelectStampScreen extends StatelessWidget {
  const SelectStampScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        previousPageTitle: '',
        middle: const Text(
          'Select Stamp',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black, size: 28),
        ),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: StreamBuilder<List<db.Stamp>>(
        stream: db.AppDatabase.instance.watchStamps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            );
          }

          final stamps = snapshot.data ?? [];

          if (stamps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stamps',
                    style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a stamp first',
                    style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey2),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stamps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stamp = stamps[index];
              return _StampItem(
                stamp: stamp,
                onTap: () async {
                  final codec = await ui.instantiateImageCodec(stamp.imageBytes);
                  final frame = await codec.getNextFrame();
                  if (context.mounted) {
                    context.router.maybePop(frame.image);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StampItem extends StatelessWidget {
  final db.Stamp stamp;
  final VoidCallback onTap;

  const _StampItem({required this.stamp, required this.onTap});

  Future<ui.Image> _bytesToImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.separator.withOpacity(0.3), width: 0.5),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Stamp thumbnail
              Container(
                width: 100,
                height: 70,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.separator.withOpacity(0.5), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<ui.Image>(
                    future: _bytesToImage(stamp.imageBytes),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return RawImage(image: snapshot.data!, fit: BoxFit.contain);
                      }
                      return const Center(child: CupertinoActivityIndicator());
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Stamp information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stamp.name ?? 'Stamp ${stamp.id}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 14, color: CupertinoColors.systemGrey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(stamp.createdAt),
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.systemGrey,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

