import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import '../database/database.dart' as db;

@RoutePage()
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        middle: const Text(
          'Statistics',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black, size: 28),
        ),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: FutureBuilder<Map<String, int>>(
          future: db.AppDatabase.instance.getStatistics(),
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

            final stats = snapshot.data ?? {};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  icon: CupertinoIcons.doc_text,
                  title: 'Total Documents',
                  value: stats['totalDocuments'] ?? 0,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: CupertinoIcons.checkmark_seal,
                  title: 'Signed Documents',
                  value: stats['signedDocuments'] ?? 0,
                  color: CupertinoColors.systemGreen,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: CupertinoIcons.circle,
                  title: 'Unsigned Documents',
                  value: stats['unsignedDocuments'] ?? 0,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: CupertinoIcons.star_fill,
                  title: 'Favorite Documents',
                  value: stats['favoriteDocuments'] ?? 0,
                  color: CupertinoColors.systemYellow,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: CupertinoIcons.pencil_ellipsis_rectangle,
                  title: 'Total Signatures',
                  value: stats['totalSignatures'] ?? 0,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: CupertinoIcons.folder,
                  title: 'Categories',
                  value: stats['categories'] ?? 0,
                  color: CupertinoColors.systemPurple,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.separator.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.systemGrey,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









