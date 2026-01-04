import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database.dart';
import '../utils/image_picker_utils.dart';

/// Screen for creating a stamp
@RoutePage()
class CreateStampScreen extends StatefulWidget {
  const CreateStampScreen({super.key});

  @override
  State<CreateStampScreen> createState() => _CreateStampScreenState();
}

class _CreateStampScreenState extends State<CreateStampScreen> {
  bool _isSaving = false;
  bool _isDrawingMode = true;
  Uint8List? _loadedImageBytes;

  // Selected stamp color
  Color _selectedColor = CupertinoColors.systemRed;

  // Available colors for stamp
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
  late GlobalKey<SfSignaturePadState> _stampKey;

  @override
  void initState() {
    super.initState();
    _stampKey = GlobalKey<SfSignaturePadState>();
  }

  /// Save stamp to database
  Future<void> _saveStamp() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      Uint8List imageBytes;

      if (_isDrawingMode) {
        // Export drawn stamp as image
        ui.Image image = await _stampKey.currentState!.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        imageBytes = byteData!.buffer.asUint8List();
      } else {
        // Use loaded image
        if (_loadedImageBytes == null) {
          throw Exception('No image loaded');
        }
        imageBytes = _loadedImageBytes!;
      }

      // Save to database
      await AppDatabase.instance.insertStamp(
        StampsCompanion(imageBytes: Value(imageBytes), name: const Value(null)),
      );

      if (!mounted) return;

      // Go back
      context.router.maybePop();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save stamp: $e'),
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

  /// Show menu to select image source
  void _showImageSourceMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _loadImageFromGallery();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 20),
                SizedBox(width: 8),
                Text('From Gallery'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _loadImageFromCamera();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('From Camera'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _loadImageFromFiles();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder, size: 20),
                SizedBox(width: 8),
                Text('From Files'),
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

  /// Load image from gallery
  Future<void> _loadImageFromGallery() async {
    try {
      final imageBytes = await ImagePickerUtils.pickImageFromGallery();
      if (imageBytes != null && mounted) {
        setState(() {
          _loadedImageBytes = imageBytes;
          _isDrawingMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load image from gallery: $e');
      }
    }
  }

  /// Load image from camera
  Future<void> _loadImageFromCamera() async {
    try {
      final imageBytes = await ImagePickerUtils.pickImageFromCamera();
      if (imageBytes != null && mounted) {
        setState(() {
          _loadedImageBytes = imageBytes;
          _isDrawingMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load image from camera: $e');
      }
    }
  }

  /// Load image from files
  Future<void> _loadImageFromFiles() async {
    try {
      final imageBytes = await ImagePickerUtils.pickImageFromFiles();
      if (imageBytes != null && mounted) {
        setState(() {
          _loadedImageBytes = imageBytes;
          _isDrawingMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load image from files: $e');
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Clear stamp pad
  void _clearStamp() {
    _stampKey.currentState?.clear();
  }

  /// Change stamp color
  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
      // Recreate key to rebuild stamp pad with new color
      _stampKey = GlobalKey<SfSignaturePadState>();
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
          'Create Stamp',
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
              // Mode selector
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: _isDrawingMode
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        setState(() {
                          _isDrawingMode = true;
                          _loadedImageBytes = null;
                        });
                      },
                      child: Text(
                        'Draw',
                        style: TextStyle(
                          color: _isDrawingMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      color: !_isDrawingMode
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _showImageSourceMenu,
                      child: Text(
                        'Load Image',
                        style: TextStyle(
                          color: !_isDrawingMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isDrawingMode) ...[
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
              ],
              const SizedBox(height: 16),
              // Stamp pad or image preview container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.separator, width: 1),
                  ),
                  child: _isDrawingMode
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SfSignaturePad(
                            key: _stampKey,
                            minimumStrokeWidth: 1,
                            maximumStrokeWidth: 3,
                            strokeColor: _selectedColor,
                            backgroundColor: CupertinoColors.transparent,
                          ),
                        )
                      : _loadedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _loadedImageBytes!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.photo,
                                    size: 64,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No image loaded',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap "Load Image" to select',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  // Clear/Remove button
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _isDrawingMode ? _clearStamp : () {
                        setState(() {
                          _loadedImageBytes = null;
                        });
                      },
                      child: Text(
                        _isDrawingMode ? 'Clear' : 'Remove',
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save button
                  Expanded(
                    child: CupertinoButton(
                      color: ((_isDrawingMode && _stampKey.currentState != null) ||
                              (!_isDrawingMode && _loadedImageBytes != null)) &&
                              !_isSaving
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: ((_isDrawingMode && _stampKey.currentState != null) ||
                              (!_isDrawingMode && _loadedImageBytes != null)) &&
                              !_isSaving
                          ? _saveStamp
                          : null,
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

