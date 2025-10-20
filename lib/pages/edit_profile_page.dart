import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/api_client.dart';
import '../data/models.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    this.apiBaseUrl = 'http://localhost:8765',
    this.token,
    this.initialName = '',
    this.initialBio = '',
    this.initialIconUrl,
  });

  final String apiBaseUrl;
  final String? token;
  final String initialName;
  final String initialBio;
  final String? initialIconUrl;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _storage = FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _bioController  = TextEditingController();

  String? _token;
  late ApiClient _api;
  XFile? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _bioController.text  = widget.initialBio;
    _prepare();
  }

  Future<void> _prepare() async {
    final t = widget.token ?? await _storage.read(key: 'jwt');
    _token = t;
    _api = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return;
    if (!mounted) return;
    setState(() => _pickedImage = x);
  }

  Future<void> _save() async {
    if (_token == null || _token!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await _api.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        icon: _pickedImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
      Navigator.pop<ProfileUser?>(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      // ← ここを修正：finally で return は使わず、条件付きで実行する
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  ImageProvider _avatarProvider() {
    if (_pickedImage != null) {
      return FileImage(File(_pickedImage!.path));
    }
    if (widget.initialIconUrl != null && widget.initialIconUrl!.isNotEmpty) {
      return NetworkImage(widget.initialIconUrl!);
    }
    return const NetworkImage('https://picsum.photos/200');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarProvider(),
                  ),
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                    tooltip: '画像を選択',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ユーザー名'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '自己紹介'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
