import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart' as db;
import '../utils/document_picker_utils.dart';
import '../utils/share_helper.dart';
import '../utils/print_helper.dart';
import '../router/app_router.dart';

enum DocumentSortBy { date, name, size }

enum DocumentFilter { all, signed, unsigned, favorites }

@RoutePage()
class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();

  static _DocumentsListScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_DocumentsListScreenState>();
  }
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DocumentSortBy _sortBy = DocumentSortBy.date;
  DocumentFilter _filter = DocumentFilter.all;
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<db.Document>> _getDocumentsStream() {
    // Determine filter values
    bool? isSigned;
    bool? isFavorite;

    if (_filter == DocumentFilter.signed) {
      isSigned = true;
    } else if (_filter == DocumentFilter.unsigned) {
      isSigned = false;
    } else if (_filter == DocumentFilter.favorites) {
      isFavorite = true;
    }

    // Convert sortBy enum to string
    String sortByString;
    switch (_sortBy) {
      case DocumentSortBy.name:
        sortByString = 'name';
        break;
      case DocumentSortBy.size:
        sortByString = 'size';
        break;
      case DocumentSortBy.date:
        sortByString = 'date';
        break;
    }

    return db.AppDatabase.instance.watchDocumentsWithFilter(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      isSigned: isSigned,
      isFavorite: isFavorite,
      categoryId: _selectedCategoryId,
      sortBy: sortByString,
      ascending: false, // Always descending for now
    );
  }

  List<db.Document> _sortDocuments(List<db.Document> documents) {
    // Documents are already sorted by the database query
    // Just ensure favorites are shown first
    final sorted = List<db.Document>.from(documents);
    sorted.sort((a, b) {
      final aFavorite = a.isFavorite;
      final bFavorite = b.isFavorite;
      if (aFavorite && !bFavorite) return -1;
      if (!aFavorite && bFavorite) return 1;
      return 0;
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        middle: const Text(
          'Documents',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showAddDocumentMenu(context),
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
                placeholder: 'Search documents...',
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
            // Filter and Sort bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: CupertinoColors.systemGrey6,
                      onPressed: () => _showFilterSheet(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getFilterIcon(), size: 16, color: CupertinoColors.systemGrey),
                          const SizedBox(width: 6),
                          Text(
                            _getFilterText(),
                            style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: CupertinoColors.systemGrey6,
                      onPressed: () => _showSortSheet(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_up_arrow_down,
                            size: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getSortText(),
                            style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Folders and Documents list
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Folders section
                  SliverToBoxAdapter(
                    child: StreamBuilder<List<db.Category>>(
                      stream: db.AppDatabase.instance.watchCategories(),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        if (categories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Folders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemGrey,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 80,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categories.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    return _FolderCard(
                                      category: category,
                                      isSelected: _selectedCategoryId == category.id,
                                      onTap: () {
                                        setState(() {
                                          if (_selectedCategoryId == category.id) {
                                            _selectedCategoryId = null;
                                          } else {
                                            _selectedCategoryId = category.id;
                                          }
                                        });
                                      },
                                      onDelete: () => _deleteFolder(context, category),
                                      onRename: () => _renameFolder(context, category),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Documents list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: StreamBuilder<List<db.Document>>(
                      stream: _getDocumentsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: CupertinoColors.systemRed),
                              ),
                            ),
                          );
                        }

                        final rawDocuments = snapshot.data ?? [];
                        final documents = _sortDocuments(rawDocuments);

                        if (documents.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text,
                                    size: 64,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No documents found' : 'No documents',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                  if (_searchQuery.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap + to add a PDF document',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.systemGrey2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final document = documents[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < documents.length - 1 ? 12 : 0,
                              ),
                              child: _DocumentItem(
                                document: document,
                                onDelete: () => _deleteDocument(context, document),
                                onTap: () {
                                  context.router.push(SignDocumentRoute(document: document));
                                },
                                onShare: (doc) => _shareDocument(context, doc),
                                onPrint: (doc) => _printDocument(context, doc),
                                onRename: (doc) => _renameDocument(context, doc),
                                onShowMenu: (ctx, doc) => _showActionMenu(ctx, doc),
                                onDuplicate: (doc) => _duplicateDocument(context, doc),
                                onToggleFavorite: (doc) => _toggleFavorite(context, doc),
                              ),
                            );
                          }, childCount: documents.length),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon() {
    switch (_filter) {
      case DocumentFilter.signed:
        return CupertinoIcons.checkmark_circle;
      case DocumentFilter.unsigned:
        return CupertinoIcons.circle;
      case DocumentFilter.favorites:
        return CupertinoIcons.star_fill;
      case DocumentFilter.all:
        return CupertinoIcons.list_bullet;
    }
  }

  String _getFilterText() {
    switch (_filter) {
      case DocumentFilter.signed:
        return 'Signed';
      case DocumentFilter.unsigned:
        return 'Unsigned';
      case DocumentFilter.favorites:
        return 'Favorites';
      case DocumentFilter.all:
        return 'All';
    }
  }

  String _getSortText() {
    switch (_sortBy) {
      case DocumentSortBy.name:
        return 'Name';
      case DocumentSortBy.size:
        return 'Size';
      case DocumentSortBy.date:
        return 'Date';
    }
  }

  void _showFilterSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter Documents'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _filter = DocumentFilter.all);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_filter == DocumentFilter.all)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_filter == DocumentFilter.all) const SizedBox(width: 8),
                const Text('All Documents'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _filter = DocumentFilter.signed);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_filter == DocumentFilter.signed)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_filter == DocumentFilter.signed) const SizedBox(width: 8),
                const Text('Signed'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _filter = DocumentFilter.unsigned);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_filter == DocumentFilter.unsigned)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_filter == DocumentFilter.unsigned) const SizedBox(width: 8),
                const Text('Unsigned'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _filter = DocumentFilter.favorites);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_filter == DocumentFilter.favorites)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_filter == DocumentFilter.favorites) const SizedBox(width: 8),
                const Text('Favorites'),
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
  }

  void _showSortSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sort Documents'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = DocumentSortBy.date);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_sortBy == DocumentSortBy.date)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_sortBy == DocumentSortBy.date) const SizedBox(width: 8),
                const Text('Date'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = DocumentSortBy.name);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_sortBy == DocumentSortBy.name)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_sortBy == DocumentSortBy.name) const SizedBox(width: 8),
                const Text('Name'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = DocumentSortBy.size);
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_sortBy == DocumentSortBy.size)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (_sortBy == DocumentSortBy.size) const SizedBox(width: 8),
                const Text('Size'),
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
  }

  void showAddDocumentMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _scanDocument(context);
            },
            child: const Text('Scan Document'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromGallery(context);
            },
            child: const Text('Choose Image'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _addDocument(context);
            },
            child: const Text('Choose PDF File'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showCreateFolderDialog(context);
            },
            child: const Text('New Folder'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _addDocument(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.pickPdfDocument();

      if (result == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      try {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      } catch (insertError) {
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        // Use a BuildContext from the widget tree
        final navigatorContext = this.context;
        if (navigatorContext.mounted) {
          showCupertinoDialog(
            context: navigatorContext,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to add document: $e'),
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

  Future<void> _scanDocument(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.scanDocument();

      if (result == null) {
        if (mounted) {
          final navigatorContext = this.context;
          if (navigatorContext.mounted) {
            showCupertinoDialog(
              context: navigatorContext,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Scan Cancelled'),
                content: const Text('Document scanning was cancelled.'),
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
        return;
      }

      if (mounted) {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        final navigatorContext = this.context;
        if (navigatorContext.mounted) {
          showCupertinoDialog(
            context: navigatorContext,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to scan document: $e'),
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

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.pickImageFromGallery();

      if (result == null) {
        if (mounted) {
          final navigatorContext = this.context;
          if (navigatorContext.mounted) {
            showCupertinoDialog(
              context: navigatorContext,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Selection Cancelled'),
                content: const Text('Image selection was cancelled.'),
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
        return;
      }

      if (mounted) {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        final navigatorContext = this.context;
        if (navigatorContext.mounted) {
          showCupertinoDialog(
            context: navigatorContext,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to pick image: $e'),
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

  Future<void> _deleteDocument(BuildContext context, db.Document document) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This action cannot be undone.'),
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
        await db.AppDatabase.instance.deleteDocument(document.id);
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete document: $e'),
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

  Future<void> _shareDocument(BuildContext context, db.Document document) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, '${document.name}.pdf'));
      await tempFile.writeAsBytes(document.pdfBytes);

      await ShareHelper.sharePdf(filePath: tempFile.path, subject: document.name);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to share document: $e'),
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

  Future<void> _printDocument(BuildContext context, db.Document document) async {
    try {
      await PrintHelper.printPdf(pdfBytes: document.pdfBytes, name: document.name);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to print document: $e'),
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

  Future<void> _renameDocument(BuildContext context, db.Document document) async {
    final textController = TextEditingController(text: document.name);

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Document'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Document name',
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

    if (result != null && result.isNotEmpty && result != document.name) {
      try {
        await db.AppDatabase.instance.updateDocument(document.copyWith(name: result));
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to rename document: $e'),
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

  Future<void> _duplicateDocument(BuildContext context, db.Document document) async {
    try {
      final newName = '${document.name.replaceAll('.pdf', '')} (Copy).pdf';
      await db.AppDatabase.instance.addDocument(pdfBytes: document.pdfBytes, fileName: newName);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to duplicate document: $e'),
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

  Future<void> _toggleFavorite(BuildContext context, db.Document document) async {
    try {
      await db.AppDatabase.instance.toggleFavorite(document.id, !document.isFavorite);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update favorite: $e'),
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

  void _showCreateFolderDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Folder name',
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
                db.AppDatabase.instance.insertCategory(db.CategoriesCompanion(name: Value(name)));
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(BuildContext context, db.Category category) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('This action cannot be undone.'),
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
        await db.AppDatabase.instance.deleteCategory(category.id);
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete folder: $e'),
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

  Future<void> _renameFolder(BuildContext context, db.Category category) async {
    final textController = TextEditingController(text: category.name);

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Folder name',
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
      try {
        await db.AppDatabase.instance.updateCategory(category.copyWith(name: result));
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to rename folder: $e'),
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

  Future<void> _changeCategory(BuildContext context, db.Document document) async {
    final categories = await db.AppDatabase.instance.getCategories();

    if (categories.isEmpty) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('No Folders'),
            content: const Text('Please create a folder first using the + menu.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Folder'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _updateDocumentCategory(document, null);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (document.categoryId == null)
                  const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20),
                if (document.categoryId == null) const SizedBox(width: 8),
                const Text('No Folder'),
              ],
            ),
          ),
          ...categories.map(
            (category) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _updateDocumentCategory(document, category.id);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (document.categoryId == category.id)
                    const Icon(
                      CupertinoIcons.checkmark,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                  if (document.categoryId == category.id) const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _updateDocumentCategory(db.Document document, int? categoryId) async {
    try {
      final updatedDocument = db.Document(
        id: document.id,
        pdfBytes: document.pdfBytes,
        name: document.name,
        createdAt: document.createdAt,
        signedAt: document.signedAt,
        isFavorite: document.isFavorite,
        categoryId: categoryId,
      );
      await db.AppDatabase.instance.updateDocument(updatedDocument);
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update category: $e'),
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

  void _showActionMenu(BuildContext context, db.Document document) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleFavorite(context, document);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  document.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  size: 20,
                  color: document.isFavorite ? CupertinoColors.systemYellow : null,
                ),
                const SizedBox(width: 8),
                Text(document.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _changeCategory(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder, size: 20),
                SizedBox(width: 8),
                Text('Change Folder'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _duplicateDocument(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc, size: 20),
                SizedBox(width: 8),
                Text('Duplicate'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _renameDocument(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(CupertinoIcons.pencil, size: 20), SizedBox(width: 8), Text('Rename')],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _shareDocument(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(CupertinoIcons.share, size: 20), SizedBox(width: 8), Text('Share')],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _printDocument(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(CupertinoIcons.printer, size: 20), SizedBox(width: 8), Text('Print')],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDocument(context, document);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(CupertinoIcons.delete, size: 20), SizedBox(width: 8), Text('Delete')],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final db.Document document;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Function(db.Document) onShare;
  final Function(db.Document) onPrint;
  final Function(db.Document) onRename;
  final Function(BuildContext, db.Document) onShowMenu;
  final Function(db.Document) onDuplicate;
  final Function(db.Document) onToggleFavorite;

  const _DocumentItem({
    required this.document,
    required this.onDelete,
    required this.onTap,
    required this.onShare,
    required this.onPrint,
    required this.onRename,
    required this.onShowMenu,
    required this.onDuplicate,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isSigned = document.signedAt != null;
    final sizeInKB = document.pdfBytes.length / 1024;
    final sizeText = sizeInKB < 1024
        ? '${sizeInKB.toStringAsFixed(1)} KB'
        : '${(sizeInKB / 1024).toStringAsFixed(2)} MB';

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Document icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSigned
                      ? CupertinoColors.systemGreen.withOpacity(0.12)
                      : CupertinoColors.systemRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSigned ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.doc_text_fill,
                  color: isSigned ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Document information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.black,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              CupertinoIcons.star_fill,
                              size: 18,
                              color: CupertinoColors.systemYellow,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              size: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(document.createdAt),
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.systemGrey,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        if (isSigned)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle,
                                size: 14,
                                color: CupertinoColors.systemGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Signed ${_formatDate(document.signedAt!)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.systemGreen,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc, size: 14, color: CupertinoColors.systemGrey),
                            const SizedBox(width: 4),
                            Text(
                              sizeText,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // More button with menu
              GestureDetector(
                onTap: () {
                  onShowMenu(context, document);
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

class _FolderCard extends StatelessWidget {
  final db.Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _FolderCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
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
        width: 80,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: CupertinoColors.systemRed, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.folder_fill,
                    color: CupertinoColors.systemRed,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.black,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
