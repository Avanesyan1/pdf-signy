import 'dart:ui' as ui;
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart';

/// Screen for creating a handwritten signature
@RoutePage()
class CreateSignatureScreen extends StatefulWidget {
  const CreateSignatureScreen({super.key});

  @override
  State<CreateSignatureScreen> createState() => _CreateSignatureScreenState();
}

class _CreateSignatureScreenState extends State<CreateSignatureScreen> {
  bool _isSaving = false;

  // Selected signature color
  Color _selectedColor = CupertinoColors.systemRed;

  // Available colors for signature
  final List<Color> _availableColors = [
    CupertinoColors.systemRed,
    CupertinoColors.black,
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPurple,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemPink,
    CupertinoColors.systemBrown,
    CupertinoColors.systemTeal,
  ];

  // Key for signature pad - recreated when color changes
  late GlobalKey<SfSignaturePadState> _signatureKey;

  @override
  void initState() {
    super.initState();
    _signatureKey = GlobalKey<SfSignaturePadState>();
  }

  /// Save signature to database
  Future<void> _saveSignature(GlobalKey<SfSignaturePadState> key) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Export signature as image
      ui.Image image = await key.currentState!.toImage();

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      // Save to database
      await AppDatabase.instance.insertSignature(
        SignaturesCompanion(imageBytes: Value(imageBytes), name: const Value(null)),
      );

      if (!mounted) return;

      // Go back
      context.router.maybePop();
    } catch (e) {
      if (kDebugMode) {
      }
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save signature: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Clear signature pad
  void _clearSignature() {
    _signatureKey.currentState?.clear();
  }

  /// Change signature color
  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
      // Recreate key to rebuild signature pad with new color
      _signatureKey = GlobalKey<SfSignaturePadState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        previousPageTitle: '',
        middle: const Text(
          'Create Signature',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Color picker
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => _changeColor(color),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.systemRed
                                : CupertinoColors.separator,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Signature pad container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.separator, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SfSignaturePad(
                      key: _signatureKey,
                      minimumStrokeWidth: 1,
                      maximumStrokeWidth: 3,
                      strokeColor: _selectedColor,
                      backgroundColor: CupertinoColors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  // Clear button
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _clearSignature,
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save button
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _isSaving ? null : () => _saveSignature(_signatureKey),
                      child: _isSaving
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
