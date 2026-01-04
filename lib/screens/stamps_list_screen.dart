import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart';
import '../router/app_router.dart';

@RoutePage()
class StampsListScreen extends StatefulWidget {
  const StampsListScreen({super.key});

  @override
  State<StampsListScreen> createState() => _StampsListScreenState();
}

class _StampsListScreenState extends State<StampsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        middle: const Text(
          'My Stamps',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            context.router.push(const CreateStampRoute());
          },
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.systemRed, size: 28),
        ),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search stamps...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Stamps list
            Expanded(
              child: StreamBuilder<List<Stamp>>(
                stream: AppDatabase.instance.watchStampsWithFilter(
                  _searchQuery.isEmpty ? null : _searchQuery,
                ),
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
                            _searchQuery.isEmpty ? 'No stamps' : 'No stamps found',
                            style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create a stamp',
                              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey2),
                            ),
                          ],
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
                      return _StampItem(stamp: stamp, onDelete: () => _deleteStamp(context, stamp));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStamp(BuildContext context, Stamp stamp) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          children: [
            const Text('Delete Stamp?'),
            const SizedBox(height: 8),
            const Text('This action cannot be undone.'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppDatabase.instance.deleteStamp(stamp.id);
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete stamp: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}

class _StampItem extends StatelessWidget {
  final Stamp stamp;
  final VoidCallback onDelete;

  const _StampItem({required this.stamp, required this.onDelete});

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
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
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
                border: Border.all(
                  color: CupertinoColors.separator.withValues(alpha: 0.5),
                  width: 1,
                ),
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
            // Delete button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 24),
            ),
          ],
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
