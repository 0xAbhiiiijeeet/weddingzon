import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_provider.dart';
import '../../../core/models/user_model.dart';

class MemberPhotoUploadScreen extends StatefulWidget {
  const MemberPhotoUploadScreen({super.key});

  @override
  State<MemberPhotoUploadScreen> createState() =>
      _MemberPhotoUploadScreenState();
}

class _MemberPhotoUploadScreenState extends State<MemberPhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];
  bool _isLoading = false;
  String? _memberId;
  User? _memberProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_memberId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _memberId = args;
        _loadMemberProfile();
      }
    }
  }

  void _loadMemberProfile() {
    final provider = context.read<FranchiseProvider>();
    try {
      final member = provider.profiles.firstWhere(
        (u) => u.id == _memberId,
        orElse: () => User(id: ''),
      );
      if (member.id.isNotEmpty) {
        setState(() {
          _memberProfile = member;
        });
      }
    } catch (e) {
      debugPrint('Error loading member profile: $e');
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking photos: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick photos')));
    }
  }

  Future<void> _upload() async {
    if (_memberId == null || _selectedPhotos.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await context.read<FranchiseProvider>().uploadPhotos(
      _memberId!,
      _selectedPhotos,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedPhotos.clear();
        });
        _loadMemberProfile();
      } else {
        final error = context.read<FranchiseProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.isNotEmpty ? error : 'Failed to upload photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeSelectedPhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _deleteExistingPhoto(String photoUrl) async {
    if (_memberId == null) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete Photo?'),
            content: const Text('Are you sure you want to delete this photo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    final success = await context.read<FranchiseProvider>().deletePhoto(
      _memberId!,
      photoUrl,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo deleted')));
        _loadMemberProfile();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete photo')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _memberProfile = context.select<FranchiseProvider, User?>((p) {
      try {
        return p.profiles.firstWhere(
          (u) => u.id == _memberId,
          orElse: () => User(id: ''),
        );
      } catch (e) {
        return null;
      }
    });

    final existingPhotos = _memberProfile?.photos ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Photos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (existingPhotos.isNotEmpty) ...[
              const Text(
                'Current Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: existingPhotos.length,
                itemBuilder: (context, index) {
                  final photo = existingPhotos[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: _isLoading
                              ? null
                              : () => _deleteExistingPhoto(photo.url),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),
            ] else if (_memberProfile != null) ...[
              const Text(
                'No photos uploaded yet.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const Divider(height: 32),
            ],

            const Text(
              'Upload New Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _selectedPhotos.isEmpty
                ? ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Select Photos'),
                  )
                : Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _selectedPhotos.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedPhotos.length) {
                            return InkWell(
                              onTap: _pickPhotos,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            );
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedPhotos[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () => _removeSelectedPhoto(index),
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Upload ${_selectedPhotos.length} Photos'),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}