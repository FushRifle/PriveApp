import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CloudinaryUploadButton extends StatelessWidget {
  final UploadType uploadType;
  final Widget child;
  final String? customFolder;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final bool showProgress;

  const CloudinaryUploadButton({
    super.key,
    required this.uploadType,
    required this.child,
    this.customFolder,
    this.onSuccess,
    this.onError,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CloudinaryCubit, CloudinaryState>(
      listener: (context, state) {
        if (state.status == UploadStatus.success &&
            state.uploadType == uploadType) {
          onSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getTypeName()} uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == UploadStatus.error) {
          onError?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isUploading = state.status == UploadStatus.uploading &&
            state.uploadType == uploadType;
        final isPicking = state.status == UploadStatus.picking &&
            state.uploadType == uploadType;

        if (isUploading && showProgress) {
          return _buildProgressButton(context, state);
        }

        return AbsorbPointer(
          absorbing: isUploading || isPicking,
          child: GestureDetector(
            onTap: () => _handleUpload(context),
            child: child,
          ),
        );
      },
    );
  }

  void _handleUpload(BuildContext context) {
    context.read<CloudinaryCubit>().uploadFile(
          type: uploadType,
          customFolder: customFolder,
        );
  }

  Widget _buildProgressButton(BuildContext context, CloudinaryState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 8),
          Text(
              'Uploading ${_getTypeName()}: ${(state.progress * 100).toInt()}%'),
        ],
      ),
    );
  }

  String _getTypeName() {
    switch (uploadType) {
      case UploadType.image:
        return 'Image';
      case UploadType.video:
        return 'Video';
      case UploadType.audio:
        return 'Audio';
      case UploadType.document:
        return 'Document';
    }
  }
}
