import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  Category({required this.id, required this.name, required this.slug});
}

class AddPortfolioPage extends StatefulWidget {
  const AddPortfolioPage({super.key});

  @override
  State<AddPortfolioPage> createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  // ▼ 共通コントローラ
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  // ▼ 機械系フィールド（Cake側のnameに合わせて用意）
  final _purposeCtrl = TextEditingController();
  final _basicSpecCtrl = TextEditingController();
  final _designUrlCtrl = TextEditingController();
  final _designDescCtrl = TextEditingController();
  final _partsListCtrl = TextEditingController();
  final _processingMethodCtrl = TextEditingController();
  final _processingNotesCtrl = TextEditingController();
  final _analysisMethodCtrl = TextEditingController();
  final _analysisResultCtrl = TextEditingController();
  final _developmentPeriodCtrl = TextEditingController();
  final _mechanicalNotesCtrl = TextEditingController();
  final _referenceLinksCtrl = TextEditingController();
  final _toolUsedCtrl = TextEditingController();
  final _materialUsedCtrl = TextEditingController();
  // 下部の重複項目もCake側に合わせたいなら同名でOK（ここでは上を使い回し）

  // ▼ プログラミング・化学
  final _githubUrlCtrl = TextEditingController();
  final _experimentSummaryCtrl = TextEditingController();

  // ▼ カテゴリ周り
  final List<Category> _categories = [
    Category(id: 1, name: '機械系', slug: 'mechanical'),
    Category(id: 2, name: 'プログラミング', slug: 'programming'),
    Category(id: 3, name: '化学', slug: 'chemistry'),
  ];
  Category? _selected; // ← 選択中カテゴリ
  final Map<String, String> _templateHints = {
    'mechanical': '設計図や解析データ、使ったツール、工学的な工夫点などを書くと◎',
    'programming': '技術スタック、言語、GitHubリンク、工夫点などを紹介！',
    'chemistry': '実験の目的、手順、考察、結果の写真などを添えるとGood！',
  };

  // ▼ サムネ（thumbnail_file）: 1枚
  File? _thumbnailFile;

  // ▼ 図面PDF（drawing_pdf）: 1枚
  PlatformFile? _drawingPdf;

  // ▼ 補足PDF（supplement_pdfs[]）: 複数
  List<PlatformFile> _supplementPdfs = [];

  // 画像選択
  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _thumbnailFile = File(picked.path));
  }

  // PDF選択（単体）
  Future<void> _pickDrawingPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _drawingPdf = result.files.first);
    }
  }

  // PDF選択（複数）
  Future<void> _pickSupplementPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true, withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _supplementPdfs = result.files);
    }
  }

  // 送信（UIだけ。API連携はこの下に「送信ペイロード例」を記載）
  void _submit() {
    if (_selected == null || _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('「カテゴリ」と「タイトル」は必須です')),
      );
      return;
    }

    // ここで multipart/form-data を組んでCakePHPにPOST予定
    // → 後述の「送信ペイロード例」を参照

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投稿を送信しました（UI確認用）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slug = _selected?.slug;

    return Scaffold(
      appBar: AppBar(title: const Text('新規投稿')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ▼ カテゴリ（Cake: category_id）
          DropdownButtonFormField<Category>(
            initialValue: _selected, 
            decoration: const InputDecoration(labelText: 'ジャンル（カテゴリ）'),
            // value: _selected,
            items: _categories
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (c) => setState(() => _selected = c),
          ),
          const SizedBox(height: 12),

          // ▼ テンプレ説明（CakeのJSテンプレに相当）
          if (slug != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _templateHints[slug] ?? '',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),

          const SizedBox(height: 16),

          // ▼ 共通欄（Cake: title, description, thumbnail_file, link）
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'タイトル')),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: '説明'),
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: null,
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickThumbnail,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _thumbnailFile == null
                  ? const Text('サムネイル画像を選択（タップ）')
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_thumbnailFile!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: '関連リンク（任意）')),

          const SizedBox(height: 24),

          // ▼ カテゴリ別の入力欄（Cakeの extra-*** に対応）
          if (slug == 'mechanical') _buildMechanicalFields(),
          if (slug == 'programming') _buildProgrammingFields(),
          if (slug == 'chemistry') _buildChemistryFields(),

          const SizedBox(height: 24),

          // ▼ PDF（図面：1枚、補足：複数）
          if (slug == 'mechanical') ...[
            _Labeled(
              label: '図面PDF（1枚）',
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickDrawingPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('選択'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _drawingPdf?.name ?? '未選択',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Labeled(
              label: '補足資料PDF（複数可）',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickSupplementPdfs,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('選択'),
                  ),
                  const SizedBox(height: 8),
                  ..._supplementPdfs.map((f) => Text('・${f.name}', overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('投稿する'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ]),
      ),
    );
  }

  // ====== カテゴリ別UI ======
  Widget _buildMechanicalFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🔧 機械系の追加情報', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      _Labeled(label: '目的・背景（purpose）', child: _multiline(_purposeCtrl)),
      _Labeled(label: '基本仕様（basic_spec）', child: _multiline(_basicSpecCtrl)),
      _Labeled(label: '設計書リンク（design_url）', child: TextField(controller: _designUrlCtrl)),
      _Labeled(label: '設計の説明（design_description）', child: _multiline(_designDescCtrl, min: 4)),
      _Labeled(label: '部品リスト（parts_list, Markdown）', child: _multiline(_partsListCtrl, min: 5)),

      _Labeled(label: '加工方法（processing_method）', child: _multiline(_processingMethodCtrl)),
      _Labeled(label: '加工ノウハウ・注意点（processing_notes）', child: _multiline(_processingNotesCtrl)),
      _Labeled(label: '解析手法（analysis_method）', child: _multiline(_analysisMethodCtrl)),
      _Labeled(label: '解析結果・考察（analysis_result）', child: _multiline(_analysisResultCtrl, min: 4)),

      _Labeled(label: '開発期間（development_period）', child: TextField(controller: _developmentPeriodCtrl)),
      _Labeled(label: '工夫点・反省（mechanical_notes）', child: _multiline(_mechanicalNotesCtrl, min: 3)),
      _Labeled(label: '参考資料・URL（reference_links, Markdown可）', child: _multiline(_referenceLinksCtrl, min: 3)),
      _Labeled(label: '使用ツール（tool_used）', child: _multiline(_toolUsedCtrl)),
      _Labeled(label: '使用材料（material_used）', child: _multiline(_materialUsedCtrl)),
    ]);
  }

  Widget _buildProgrammingFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('💻 プログラミング', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _Labeled(label: 'GitHub URL（github_url）', child: TextField(controller: _githubUrlCtrl)),
      _Labeled(label: '使用言語・スタック（任意）', child: _multiline(TextEditingController())),
    ]);
  }

  Widget _buildChemistryFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🧪 化学', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _Labeled(label: '実験の概要（experiment_summary）', child: _multiline(_experimentSummaryCtrl, min: 3)),
      _Labeled(label: '考察・結果（analysis_result 等）', child: _multiline(_analysisResultCtrl, min: 3)),
    ]);
  }

  // ====== ヘルパ ======
  Widget _multiline(TextEditingController c, {int min = 3}) {
    return TextField(
      controller: c,
      minLines: min,
      maxLines: null,
      keyboardType: TextInputType.multiline,
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}
