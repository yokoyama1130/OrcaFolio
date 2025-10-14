import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployerPostPage extends StatefulWidget {
  const EmployerPostPage({super.key});

  @override
  State<EmployerPostPage> createState() => _EmployerPostPageState();
}

class _EmployerPostPageState extends State<EmployerPostPage> {
  // 共通
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String? _category; // slug想定: mechanical/programming/chemistry
  File? _thumbnail;

  // 募集要項（企業向け追加）
  final _positionCtrl = TextEditingController();     // 募集職種
  final _locationCtrl = TextEditingController();     // 勤務地/リモート
  final _employmentCtrl = TextEditingController();   // 雇用形態
  final _salaryCtrl = TextEditingController();       // 報酬/給与
  final _contactCtrl = TextEditingController();      // 連絡先メール
  final _skillsCtrl = TextEditingController();       // 歓迎スキル

  Future<void> _pickThumb() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _thumbnail = File(picked.path));
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('「カテゴリ」と「タイトル」は必須です'),
      ));
      return;
    }
    // Cake側はprefixでcompany_idを付与してくれる前提
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('会社として投稿を送信しました（UI）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会社として投稿')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 会社アカウント警告（Cakeの $isEmployer に対応）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('会社アカウントとして投稿します', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'ジャンル（カテゴリ）'),
            items: const [
              DropdownMenuItem(value: 'mechanical', child: Text('機械系')),
              DropdownMenuItem(value: 'programming', child: Text('プログラミング')),
              DropdownMenuItem(value: 'chemistry', child: Text('化学')),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),

          if (_category != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _category == 'mechanical'
                    ? '設計図・解析・使用ツールなどを添えると◎'
                    : _category == 'programming'
                        ? '技術スタック・GitHub・工夫点などを添えると◎'
                        : '実験の目的や考察・結果などを添えると◎',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),

          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'タイトル')),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: '説明'),
            minLines: 4,
            maxLines: null,
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickThumb,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _thumbnail == null
                  ? const Text('サムネイル画像（タップで選択）')
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_thumbnail!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: '関連リンク（任意）')),

          const Divider(height: 32),

          const Text('募集要項（任意）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _positionCtrl, decoration: const InputDecoration(labelText: '募集職種')),
          const SizedBox(height: 8),
          TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: '勤務地 / リモート')),
          const SizedBox(height: 8),
          TextField(controller: _employmentCtrl, decoration: const InputDecoration(labelText: '雇用形態')),
          const SizedBox(height: 8),
          TextField(controller: _salaryCtrl, decoration: const InputDecoration(labelText: '報酬 / 給与')),
          const SizedBox(height: 8),
          TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: '連絡先メール')),
          const SizedBox(height: 8),
          TextField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(labelText: '歓迎スキル（カンマ区切り）'),
            minLines: 2, maxLines: null,
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('投稿する'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ]),
      ),
    );
  }
}
