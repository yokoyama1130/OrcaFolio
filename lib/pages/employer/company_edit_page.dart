import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CompanyEditPage extends StatefulWidget {
  const CompanyEditPage({super.key});

  @override
  State<CompanyEditPage> createState() => _CompanyEditPageState();
}

class _CompanyEditPageState extends State<CompanyEditPage> {
  final _nameCtrl = TextEditingController(text: 'Calcraft Robotics Inc.');
  final _aboutCtrl = TextEditingController(
      text: '産業ロボットとエンジニア採用をつなぐプラットフォーム開発。');
  final _siteCtrl = TextEditingController(text: 'https://example.com');
  File? _logo;

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _logo = File(picked.path));
  }

  void _save() {
    // TODO: CakePHP Employer/Companies/update にPOST
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('会社プロフィールを更新しました')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会社プロフィール編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _logo != null
                    ? FileImage(_logo!)
                    : const NetworkImage('https://picsum.photos/200?company')
                        as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '会社名'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aboutCtrl,
            minLines: 3,
            maxLines: null,
            decoration: const InputDecoration(labelText: '会社概要'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _siteCtrl,
            decoration: const InputDecoration(labelText: '公式サイトURL'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
