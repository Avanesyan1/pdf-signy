import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart' as db;

@RoutePage()
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        middle: const Text(
          'Categories',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black, size: 28),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showCreateCategoryDialog(context),
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.systemRed, size: 28),
        ),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: StreamBuilder<List<db.Category>>(
          stream: db.AppDatabase.instance.watchCategories(),
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

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.folder, size: 64, color: CupertinoColors.systemGrey),
                    const SizedBox(height: 16),
                    Text(
                      'No categories',
                      style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create a category',
                      style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey2),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryItem(
                  category: category,
                  onTap: () {
                    // Navigate to filtered documents list
                    context.router.maybePop(category);
                  },
                  onDelete: () => _deleteCategory(context, category),
                  onRename: () => _renameCategory(context, category),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Category'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Category name',
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Create'),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                db.AppDatabase.instance.insertCategory(
                  db.CategoriesCompanion(name: Value(name)),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, db.Category category) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('Documents in this category will be moved to uncategorized.'),
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
      await db.AppDatabase.instance.deleteCategory(category.id);
    }
  }

  Future<void> _renameCategory(BuildContext context, db.Category category) async {
    final textController = TextEditingController(text: category.name);

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Category'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Category name',
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Rename'),
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != category.name) {
      await db.AppDatabase.instance.updateCategory(
        category.copyWith(name: result),
      );
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final db.Category category;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _CategoryItem({
    required this.category,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.folder_fill,
                  color: CupertinoColors.systemBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onRename();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.pencil, size: 20),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.delete, size: 20),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

