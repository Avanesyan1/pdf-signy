import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import '../router/app_router.dart';
import '../utils/document_picker_utils.dart';
import '../database/database.dart' as db;

@RoutePage()
class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  static void _showAddDocumentMenu(BuildContext context) {
    // Save the original context before showing the popup
    final originalContext = context;

    showCupertinoModalPopup(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(popupContext).pop();
              if (originalContext.mounted) {
                await _handleScanDocument(originalContext);
              }
            },
            child: const Text('Scan Document'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(popupContext).pop();
              if (originalContext.mounted) {
                await _handlePickImageFromGallery(originalContext);
              }
            },
            child: const Text('Choose Image'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(popupContext).pop();
              if (originalContext.mounted) {
                await _handleAddDocument(originalContext);
              }
            },
            child: const Text('Choose PDF File'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(popupContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _handleScanDocument(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.scanDocument();
      if (result != null && context.mounted) {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
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

  static Future<void> _handlePickImageFromGallery(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.pickImageFromGallery();
      if (result != null && context.mounted) {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
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

  static Future<void> _handleAddDocument(BuildContext context) async {
    try {
      final result = await DocumentPickerUtils.pickPdfDocument();
      if (result != null && context.mounted) {
        await db.AppDatabase.instance.addDocument(
          pdfBytes: result.bytes,
          fileName: result.fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
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

  void _handleAddButtonTap(BuildContext context, TabsRouter tabsRouter) {
    // Always show add document menu regardless of active tab
    if (context.mounted) {
      _showAddDocumentMenu(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DocumentsListRoute(),
        SignaturesListRoute(),
        StampsListRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.white,
          child: Stack(
            children: [
              // Tab content
              child,
              // Custom tab bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border(top: BorderSide(color: CupertinoColors.separator, width: 0.5)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Documents tab
                          _TabButton(
                            icon: 'assets/documents.png',
                            label: 'Documents',
                            isActive: tabsRouter.activeIndex == 0,
                            onTap: () => tabsRouter.setActiveIndex(0),
                          ),
                          // Signatures tab
                          _TabButton(
                            icon: 'assets/signature.png',
                            label: 'Signatures',
                            isActive: tabsRouter.activeIndex == 1,
                            onTap: () => tabsRouter.setActiveIndex(1),
                          ),
                          // Add button (center)
                          _AddButton(onTap: () => _handleAddButtonTap(context, tabsRouter)),
                          // Stamps tab
                          _TabButton(
                            icon: 'assets/stamp.png',
                            label: 'Stamps',
                            isActive: tabsRouter.activeIndex == 2,
                            onTap: () => tabsRouter.setActiveIndex(2),
                          ),
                          // Settings tab
                          _TabButton(
                            icon: 'assets/settings.png',
                            label: 'Settings',
                            isActive: tabsRouter.activeIndex == 3,
                            onTap: () => tabsRouter.setActiveIndex(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                isActive ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                BlendMode.srcIn,
              ),
              child: Image.asset(icon, width: 24, height: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 28),
        ),
      ),
    );
  }
}
