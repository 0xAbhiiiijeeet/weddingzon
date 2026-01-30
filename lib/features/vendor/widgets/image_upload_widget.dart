import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageUploadWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(List<String>) onImagesSelected;
  final int maxImages;

  const ImageUploadWidget({
    Key? key,
    required this.imageUrls,
    required this.onImagesSelected,
    this.maxImages = 5,
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  List<String> _localImagePaths = [];

  Future<void> _pickImages() async {
    final remainingSlots = widget.maxImages - _localImagePaths.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final newPaths = images
          .take(remainingSlots)
          .map((xFile) => xFile.path)
          .toList();

      setState(() {
        _localImagePaths.addAll(newPaths);
      });

      widget.onImagesSelected(_localImagePaths);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _localImagePaths.removeAt(index);
    });
    widget.onImagesSelected(_localImagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_localImagePaths.isEmpty && widget.imageUrls.isEmpty)
          InkWell(
            onTap: _pickImages,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_localImagePaths.isNotEmpty || widget.imageUrls.isNotEmpty)
          Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._localImagePaths.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    return _buildImagePreview(
                      image: FileImage(File(path)),
                      onRemove: () => _removeImage(index),
                    );
                  }),
                  ...widget.imageUrls.map((url) {
                    return _buildImagePreview(
                      image: NetworkImage(url),
                      onRemove: null,
                    );
                  }),
                  if (_localImagePaths.length + widget.imageUrls.length <
                      widget.maxImages)
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_localImagePaths.length + widget.imageUrls.length}/${widget.maxImages} images',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePreview({
    required ImageProvider image,
    required VoidCallback? onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: image,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
