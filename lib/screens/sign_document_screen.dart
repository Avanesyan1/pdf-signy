import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart' as db;
import '../pdf/widgets/signature_overlay_widget.dart';
import '../pdf/helper/signature_utils.dart';
import '../router/app_router.dart';
import '../services/premium_service.dart';
import '../services/app_logger.dart';
import '../services/analytics_service.dart';

@RoutePage()
class SignDocumentScreen extends StatefulWidget {
  final db.Document document;

  const SignDocumentScreen({super.key, required this.document});

  @override
  State<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends State<SignDocumentScreen> {
  PDFViewController? _pdfController;
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  String? _tempPdfPath;
  ui.Image? _signatureImage;
  Uint8List? _signaturePng;
  final List<SignaturePlacement> _placements = [];
  final SignatureUtils _sigUtils = const SignatureUtils();
  Size _pdfViewSize = Size.zero;
  int _currentPage = 0;
  int _pageCount = 0;
  bool _pdfVisible = true;
  final Key _pdfKey = ValueKey('pdf_view_${DateTime.now().millisecondsSinceEpoch}');
  final Key _scaffoldKey = ValueKey('sign_document_scaffold');
  bool _isPinchingSignature = false;
  double? _pinchInitialScale;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isNavigatingAway = false;
  bool _isStamp = false; // Track if current image is a stamp

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      final m = _transformationController.value;
      final newScale = m.getMaxScaleOnAxis();
      if (mounted && (newScale - _currentScale).abs() > 0.01) {
        setState(() {
          _currentScale = newScale;
        });
      }
    });
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'temp_${widget.document.id}.pdf'));
      await tempFile.writeAsBytes(widget.document.pdfBytes);

      if (mounted) {
        setState(() {
          _tempPdfPath = tempFile.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load PDF: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSignature() async {
    final result = await context.router.push(const SelectSignatureRoute());
    if (result != null && result is ui.Image) {
      await _loadSignature(result, isStamp: false);
    }
  }

  Future<void> _selectStamp() async {
    final result = await context.router.push(const SelectStampRoute());
    if (result != null && result is ui.Image) {
      await _loadSignature(result, isStamp: true);
    }
  }

  void _showSelectMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _selectSignature();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 20),
                SizedBox(width: 8),
                Text('Select Signature'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _selectStamp();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.checkmark_seal, size: 20),
                SizedBox(width: 8),
                Text('Select Stamp'),
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

  Future<void> _loadSignature(ui.Image image, {bool isStamp = false}) async {
    try {
      _signatureImage = image;
      _signaturePng = await _sigUtils.imageToPngBytes(image);
      _isStamp = isStamp; // Store stamp flag

      if (_placements.isEmpty) {
        double initialScale;
        if (isStamp) {
          // For stamps, calculate scale to fit within 250x250 max size
          const maxSize = 250.0;
          final imageWidth = image.width.toDouble();
          final imageHeight = image.height.toDouble();

          // Calculate scale to fit within maxSize while maintaining aspect ratio
          final scaleX = maxSize / imageWidth;
          final scaleY = maxSize / imageHeight;
          initialScale = scaleX < scaleY ? scaleX : scaleY;

          // Ensure scale doesn't exceed 1.0 (don't upscale)
          if (initialScale > 1.0) {
            initialScale = 1.0;
          }

          // Also ensure minimum scale (at least 0.3)
          if (initialScale < 0.3) {
            initialScale = 0.3;
          }
        } else {
          // Use default scale for signatures
          initialScale = 0.6;
        }

        final placement = SignaturePlacement(
          offsetDx: _pdfViewSize.width / 2 - 100,
          offsetDy: _pdfViewSize.height / 2 - 50,
          page: _currentPage,
          scale: initialScale,
        );
        _centerPlacement(placement);
        _placements.add(placement);
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        _showError('Failed to load ${isStamp ? 'stamp' : 'signature'}: $e');
      }
    }
  }

  Offset _getContentCenter() {
    final m = _transformationController.value;
    final s = m.getMaxScaleOnAxis();
    final double tX = m.storage[12];
    final double tY = m.storage[13];
    final viewerCenterX = _pdfViewSize.width / 2.0;
    final viewerCenterY = _pdfViewSize.height / 2.0;
    final contentCenterX = (viewerCenterX - tX) / s;
    final contentCenterY = (viewerCenterY - tY) / s;
    return Offset(contentCenterX, contentCenterY);
  }

  void _centerPlacement(SignaturePlacement p) {
    if (_signatureImage == null) return;
    final img = _signatureImage!;
    final center = _getContentCenter();
    final w = img.width.toDouble() * p.scale;
    final h = img.height.toDouble() * p.scale;
    p.offsetDx = center.dx - w / 2.0;
    p.offsetDy = center.dy - h / 2.0;
  }

  void _addPlacementForCurrentPage() {
    if (_signatureImage == null) return;
    setState(() {
      double baseScale;
      if (_isStamp) {
        // For stamps, calculate scale to fit within 250x250 max size
        const maxSize = 250.0;
        final imageWidth = _signatureImage!.width.toDouble();
        final imageHeight = _signatureImage!.height.toDouble();

        // Calculate scale to fit within maxSize while maintaining aspect ratio
        final scaleX = maxSize / imageWidth;
        final scaleY = maxSize / imageHeight;
        baseScale = scaleX < scaleY ? scaleX : scaleY;

        // Ensure scale doesn't exceed 1.0 (don't upscale)
        if (baseScale > 1.0) {
          baseScale = 1.0;
        }

        // Also ensure minimum scale (at least 0.3)
        if (baseScale < 0.3) {
          baseScale = 0.3;
        }
      } else {
        // Use default scale for signatures
        baseScale = 0.6;
      }

      final p = _sigUtils.addPlacementForPage(
        placements: _placements,
        currentPage: _currentPage,
        baseScale: baseScale,
      );
      _centerPlacement(p);
      _placements.add(p);
    });
  }

  void _removePlacement(SignaturePlacement placement) {
    setState(() {
      _placements.remove(placement);
    });
  }

  Future<void> _savePdfWithSignatures() async {
    // Log save button press
    AppLogger().info('Save button pressed for document ID: ${widget.document.id}');

    if (_tempPdfPath == null ||
        _signaturePng == null ||
        _signatureImage == null ||
        _placements.isEmpty) {
      _showError('Please add a signature first');
      return;
    }

    // Check premium status and free signatures limit
    final hasPremium = PremiumService.instance.havePremium.value;
    bool shouldIncrementCounter = false;
    
    AppLogger().info('Save check - HasPremium: $hasPremium, DocumentID: ${widget.document.id}');
    
    if (!hasPremium) {
      final prefs = await SharedPreferences.getInstance();
      
      // Get list of signed document IDs
      final signedDocIdsString = prefs.getString('free_signed_document_ids') ?? '';
      final signedDocIds = signedDocIdsString.isEmpty 
          ? <int>[] 
          : signedDocIdsString.split(',').map((e) => int.tryParse(e)).whereType<int>().toList();
      
      // Check if this document was already signed for free
      final alreadySignedForFree = signedDocIds.contains(widget.document.id);
      
      AppLogger().info('Free signatures check - Document ID: ${widget.document.id}, Already in list: $alreadySignedForFree, Total signed: ${signedDocIds.length}, List: $signedDocIds');
      
      if (alreadySignedForFree) {
        // Document already in free list - allow save without restrictions
        AppLogger().info('Document already in free list. Allowing save without counting.');
      } else {
        // Document not in free list - check limit
        // If document was signed before but not in list, add it to list if limit allows
        final wasSignedBefore = widget.document.signedAt != null;
        
        if (wasSignedBefore && signedDocIds.length < 1) {
          // Document was signed before but not in list - add it now (grandfathered)
          shouldIncrementCounter = true;
          AppLogger().info('Document was signed before but not in list. Adding to list (grandfathered).');
        } else if (signedDocIds.length >= 1) {
          // Limit reached - show paywall
          AppLogger().info('Free signature limit reached (${signedDocIds.length} documents). Opening paywall.');
          AnalyticsService.instance.logFreeSignatureLimitReached();
          AnalyticsService.instance.logPaywallShown(source: 'free_limit_reached');
          // Open paywall directly
          if (mounted) {
            await context.router.push(const PaywallRoute());
          }
          return;
        } else {
          // New document, limit not reached - mark for increment
          shouldIncrementCounter = true;
          AppLogger().info('Preparing to use free signature for document ID: ${widget.document.id}');
        }
      }
    } else {
      AppLogger().info('User has premium. Allowing save without restrictions.');
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final document = PdfDocument(inputBytes: File(_tempPdfPath!).readAsBytesSync());
      final sigWidth = _signatureImage!.width.toDouble();
      final sigHeight = _signatureImage!.height.toDouble();
      final viewerW = _pdfViewSize.width == 0 ? 1.0 : _pdfViewSize.width;
      final viewerH = _pdfViewSize.height == 0 ? 1.0 : _pdfViewSize.height;
      final pdfImage = PdfBitmap(_signaturePng!);

      for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        final page = document.pages[pageIndex];
        final pageSize = page.getClientSize();
        final pageW = pageSize.width;
        final pageH = pageSize.height;

        final scale =
            (viewerW / pageW).clamp(0, double.infinity) <
                (viewerH / pageH).clamp(0, double.infinity)
            ? viewerW / pageW
            : viewerH / pageH;

        final displayedW = pageW * scale;
        final displayedH = pageH * scale;
        final offsetX = (viewerW - displayedW) / 2.0;
        final offsetY = (viewerH - displayedH) / 2.0;

        final placementsForPage = _placements.where((p) => p.page == pageIndex);
        for (final p in placementsForPage) {
          final dx = (p.offsetDx - offsetX) / scale;
          final dy = (p.offsetDy - offsetY) / scale;
          final drawW = (sigWidth * p.scale) / scale;
          final drawH = (sigHeight * p.scale) / scale;

          page.graphics.drawImage(pdfImage, Rect.fromLTWH(dx, dy, drawW, drawH));
        }
      }

      final List<int> signedBytes = await document.save();
      document.dispose();

      // Update existing document in database with signed date
      final updatedDocument = db.Document(
        id: widget.document.id,
        pdfBytes: Uint8List.fromList(signedBytes),
        name: widget.document.name,
        createdAt: widget.document.createdAt,
        signedAt: DateTime.now(),
        isFavorite: widget.document.isFavorite,
      );
      await db.AppDatabase.instance.updateDocument(updatedDocument);

      // Increment free signature counter AFTER successful save
      if (shouldIncrementCounter && !hasPremium) {
        final prefs = await SharedPreferences.getInstance();
        final signedDocIdsString = prefs.getString('free_signed_document_ids') ?? '';
        final signedDocIds = signedDocIdsString.isEmpty 
            ? <int>[] 
            : signedDocIdsString.split(',').map((e) => int.tryParse(e)).whereType<int>().toList();
        
        // Double check that document is not already in the list (race condition protection)
        if (!signedDocIds.contains(widget.document.id)) {
          signedDocIds.add(widget.document.id);
          await prefs.setString('free_signed_document_ids', signedDocIds.join(','));
          AppLogger().info('Free signature used. Document ID: ${widget.document.id}. Total used: ${signedDocIds.length}');
          AnalyticsService.instance.logFreeSignatureUsed(documentId: widget.document.id);
        }
      }

      // Log document signed event
      AnalyticsService.instance.logDocumentSigned(
        isFree: !hasPremium,
        documentId: widget.document.id,
      );

      if (mounted) {
        // Navigate back immediately
        _isNavigatingAway = true;
        if (mounted) {
          context.router.maybePop();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<int> _indicesForCurrentPage() {
    final List<int> result = [];
    for (int i = 0; i < _placements.length; i++) {
      if (_placements[i].page == _currentPage) result.add(i);
    }
    return result;
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

  @override
  void dispose() {
    _transformationController.dispose();
    _pdfController = null;
    if (_tempPdfPath != null) {
      try {
        File(_tempPdfPath!).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tempPdfPath == null) {
      return CupertinoPageScaffold(
        key: _scaffoldKey,
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          backgroundColor: CupertinoColors.white,
          previousPageTitle: '',
          middle: const Text(
            'Sign Document',
            style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              if (!_isSaving) {
                context.router.maybePop();
              }
            },
            child: const Icon(CupertinoIcons.back, color: CupertinoColors.black, size: 28),
          ),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final hasSignature = _signatureImage != null && _placements.isNotEmpty;

    return CupertinoPageScaffold(
      key: _scaffoldKey,
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        previousPageTitle: '',
        middle: Text(
          widget.document.name,
          style: const TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving
              ? null
              : () {
                  if (!_isSaving && !_isNavigatingAway) {
                    _isNavigatingAway = true;
                    context.router.maybePop();
                  }
                },
          child: Icon(
            CupertinoIcons.back,
            color: _isSaving ? CupertinoColors.systemGrey : CupertinoColors.black,
            size: 28,
          ),
        ),
        trailing: hasSignature
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addPlacementForCurrentPage,
                child: const Icon(
                  CupertinoIcons.add_circled,
                  color: CupertinoColors.systemRed,
                  size: 28,
                ),
              )
            : null,
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.separator, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _pdfViewSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          panEnabled: true,
                          scaleEnabled: !_isPinchingSignature,
                          clipBehavior: Clip.none,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _pdfVisible
                                    ? PDFView(
                                        key: _pdfKey,
                                        filePath: _tempPdfPath!,
                                        enableSwipe: false,
                                        swipeHorizontal: true,
                                        autoSpacing: true,
                                        pageFling: false,
                                        backgroundColor: CupertinoColors.systemGrey6,
                                        fitPolicy: FitPolicy.WIDTH,
                                        onViewCreated: (controller) {
                                          setState(() {
                                            _pdfController = controller;
                                          });
                                        },
                                        onRender: (pages) {
                                          setState(() {
                                            _pageCount = pages ?? 0;
                                          });
                                        },
                                        onPageChanged: (page, total) {
                                          setState(() {
                                            _currentPage = page ?? 0;
                                            _pageCount = total ?? _pageCount;
                                          });
                                        },
                                        onError: (error) {
                                          _showError('PDF error: $error');
                                        },
                                        onPageError: (page, error) {
                                          // Ignore page errors
                                        },
                                      )
                                    : const SizedBox(key: ValueKey('pdf_hidden')),
                              ),
                              if (hasSignature)
                                ..._indicesForCurrentPage().map((idx) {
                                  final placement = _placements[idx];
                                  final img = _signatureImage!;
                                  final baseW = img.width.toDouble();
                                  final baseH = img.height.toDouble();
                                  final width = baseW * placement.scale;
                                  final height = baseH * placement.scale;
                                  return SignatureOverlayWidget(
                                    key: ValueKey(placement.hashCode),
                                    left: placement.offsetDx,
                                    top: placement.offsetDy,
                                    width: width,
                                    height: height,
                                    image: img,
                                    onDragDelta: (delta) {
                                      setState(() {
                                        placement.offsetDx += delta.dx;
                                        placement.offsetDy += delta.dy;
                                      });
                                    },
                                    onPinchStart: () {
                                      setState(() {
                                        _isPinchingSignature = true;
                                        _pinchInitialScale = placement.scale;
                                      });
                                    },
                                    onPinchUpdate: (scaleFactor) {
                                      if (_pinchInitialScale == null) return;
                                      setState(() {
                                        final newScale = (_pinchInitialScale! * scaleFactor).clamp(
                                          0.2,
                                          3.0,
                                        );
                                        final currW = baseW * placement.scale;
                                        final currH = baseH * placement.scale;
                                        final centerX = placement.offsetDx + currW / 2.0;
                                        final centerY = placement.offsetDy + currH / 2.0;
                                        final newW = baseW * newScale;
                                        final newH = baseH * newScale;
                                        placement.offsetDx = centerX - newW / 2.0;
                                        placement.offsetDy = centerY - newH / 2.0;
                                        placement.scale = newScale;
                                      });
                                    },
                                    onPinchEnd: () {
                                      setState(() {
                                        _isPinchingSignature = false;
                                        _pinchInitialScale = null;
                                      });
                                    },
                                    onDoubleTap: () => _removePlacement(placement),
                                    onResizeDelta: (delta) {
                                      setState(() {
                                        placement.offsetDx += delta.dx;
                                        placement.offsetDy += delta.dy;
                                      });
                                    },
                                  );
                                }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_pageCount > 1)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.separator, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: _currentPage > 0 && _pdfController != null
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: (_currentPage > 0 && _pdfController != null)
                          ? () async {
                              final prev = _currentPage - 1;
                              if (prev >= 0) {
                                await _pdfController!.setPage(prev);
                              }
                            }
                          : null,
                      child: const Text(
                        'Previous',
                        style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${_pageCount == 0 ? '-' : _pageCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color:
                          (_pageCount > 0 &&
                              _currentPage < _pageCount - 1 &&
                              _pdfController != null)
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(8),
                      onPressed:
                          (_pageCount > 0 &&
                              _currentPage < _pageCount - 1 &&
                              _pdfController != null)
                          ? () async {
                              final next = _currentPage + 1;
                              if (next < _pageCount) {
                                await _pdfController!.setPage(next);
                              }
                            }
                          : null,
                      child: const Text(
                        'Next',
                        style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                border: Border(top: BorderSide(color: CupertinoColors.separator, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: _showSelectMenu,
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                color: CupertinoColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            color: hasSignature && !_isSaving
                                ? CupertinoColors.systemRed
                                : CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: hasSignature && !_isSaving ? _savePdfWithSignatures : null,
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
          ],
        ),
          ),
          // Loading overlay
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black.withOpacity(0.3),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(
                        radius: 20,
                        color: CupertinoColors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Signing document...',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
