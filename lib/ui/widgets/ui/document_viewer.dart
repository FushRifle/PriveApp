import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewer extends StatefulWidget {
  final String documentUrl;
  final String? fileName;
  final String? caption;

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    this.fileName,
    this.caption,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isLoading = false;
  String? _error;
  String? _fileExtension;
  bool _hasAutoOpened = false;

  @override
  void initState() {
    super.initState();
    _extractFileExtension();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasAutoOpened) {
        _hasAutoOpened = true;
        _openDocument();
      }
    });
  }

  void _extractFileExtension() {
    final uri = Uri.tryParse(widget.documentUrl);
    final fileName = widget.fileName ??
        (uri != null && uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : '');

    if (fileName.contains('.')) {
      final extension = fileName.split('.').last.split('?').first.toLowerCase();
      if (extension.length <= 6) {
        _fileExtension = extension;
      }
    }
  }

  Future<void> _openDocument() async {
    if (_isLoading) return;

    final documentUri = Uri.tryParse(widget.documentUrl);
    if (documentUri == null || !documentUri.hasScheme) {
      setState(() {
        _error = 'Invalid document link';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        await _openExternal(documentUri);
        return;
      }

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = _safeFileName(
        widget.fileName ?? 'document.${_fileExtension ?? 'pdf'}',
      );
      final filePath = '${tempDir.path}/$fileName';

      await dio.downloadUri(documentUri, filePath);

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        await _openExternal(documentUri);

        if (!mounted) return;
        setState(() {
          _error = result.message.isNotEmpty
              ? result.message
              : 'No app found to open this document';
        });
      }
    } catch (e) {
      try {
        await _openExternal(documentUri);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _error = 'Unable to open document';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openExternal(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception('Could not open document link');
    }
  }

  String _safeFileName(String fileName) {
    final trimmed = fileName.trim();
    final fallback = 'document.${_fileExtension ?? 'pdf'}';
    final safeName = (trimmed.isEmpty ? fallback : trimmed)
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^\w.\- ]'), '_');

    if (safeName.contains('.')) {
      return safeName;
    }

    return '$safeName.${_fileExtension ?? 'pdf'}';
  }

  IconData _getFileIcon() {
    switch (_fileExtension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (_fileExtension) {
      case 'pdf':
        return AppColors.red;
      case 'doc':
      case 'docx':
        return AppColors.blue;
      case 'xls':
      case 'xlsx':
        return AppColors.green;
      case 'ppt':
      case 'pptx':
        return AppColors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.fileName ?? 'Document Viewer',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Document Preview
            Expanded(
              child: Center(
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Downloading document...',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      )
                    : _error != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _openDocument,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  _getFileIcon(),
                                  size: 64,
                                  color: _getFileColor(),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _fileExtension?.toUpperCase() ?? 'DOCUMENT',
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openDocument,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            // Caption
            if (widget.caption != null &&
                widget.caption!.isNotEmpty &&
                !_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.caption!,
                  style: const TextStyle(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
