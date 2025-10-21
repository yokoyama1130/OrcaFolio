// lib/pages/add_portfolio_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../data/api_client.dart'; // ← NamedBytesFile / ApiClient を使う

// カテゴリは const で作れるように
class Category {
  final int id;
  final String name;
  final String slug;
  const Category({required this.id, required this.name, required this.slug});
}

class AddPortfolioPage extends StatefulWidget {
  const AddPortfolioPage({
    super.key,
    required this.apiBaseUrl,
    required this.token,
  });

  final String apiBaseUrl;
  final String token;

  @override
  State<AddPortfolioPage> createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  // 共通コントローラ
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  // 機械系
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

  // プログラミング・化学
  final _githubUrlCtrl = TextEditingController();
  final _experimentSummaryCtrl = TextEditingController();

  // カテゴリ
  final List<Category> _categories = const [
    Category(id: 1, name: '機械系', slug: 'mechanical'),
    Category(id: 2, name: 'プログラミング', slug: 'programming'),
    Category(id: 3, name: '化学', slug: 'chemistry'),
  ];
  Category? _selected;

  final Map<String, String> _templateHints = const {
    'mechanical': '設計図や解析データ、使ったツール、工学的な工夫点などを書くと◎',
    'programming': '技術スタック、言語、GitHubリンク、工夫点などを紹介！',
    'chemistry': '実験の目的、手順、考察、結果の写真などを添えるとGood！',
  };

  // ファイル
  File? _thumbnailFile;                     // サムネ（必須：サーバで検証）
  PlatformFile? _drawingPdf;               // 図面PDF（任意）
  List<PlatformFile> _supplementPdfs = []; // 補足PDF（任意・複数）

  bool _submitting = false;

  @override
  void dispose() {
    // 共通
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    // 機械系
    _purposeCtrl.dispose();
    _basicSpecCtrl.dispose();
    _designUrlCtrl.dispose();
    _designDescCtrl.dispose();
    _partsListCtrl.dispose();
    _processingMethodCtrl.dispose();
    _processingNotesCtrl.dispose();
    _analysisMethodCtrl.dispose();
    _analysisResultCtrl.dispose();
    _developmentPeriodCtrl.dispose();
    _mechanicalNotesCtrl.dispose();
    _referenceLinksCtrl.dispose();
    _toolUsedCtrl.dispose();
    _materialUsedCtrl.dispose();
    // プログラミング・化学
    _githubUrlCtrl.dispose();
    _experimentSummaryCtrl.dispose();
    super.dispose();
  }

  // 画像選択（サムネ）
  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _thumbnailFile = File(picked.path));
    }
  }

  // PDF選択（単体）
  Future<void> _pickDrawingPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _drawingPdf = result.files.first);
    }
  }

  // PDF選択（複数）
  Future<void> _pickSupplementPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _supplementPdfs = result.files);
    }
  }

  /// PlatformFile.bytes が null の場合は path から読み込み（実機対策）
  Future<List<int>> _bytesOf(PlatformFile f) async {
    if (f.bytes != null) return f.bytes!;
    if (f.path != null) return await File(f.path!).readAsBytes();
    throw Exception('ファイルの読み込みに失敗しました: ${f.name}');
  }

  // 送信
  Future<void> _submit() async {
    // 画面側の早期バリデーション（サーバも description/thumbnail を見ます）
    if (_selected == null || _titleCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('「カテゴリ」と「タイトル」は必須です')),
        );
      }
      return;
    }
    if (_thumbnailFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サムネイル画像を選択してください')),
        );
      }
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('説明は1文字以上入力してください')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ApiClient(baseUrl: widget.apiBaseUrl, token: widget.token);

      // PDF を NamedBytesFile に変換（ApiClient の型）
      NamedBytesFile? drawing;
      if (_drawingPdf != null) {
        final b = await _bytesOf(_drawingPdf!);
        drawing = NamedBytesFile(b, _drawingPdf!.name);
      }

      final supps = <NamedBytesFile>[];
      for (final f in _supplementPdfs) {
        final b = await _bytesOf(f);
        supps.add(NamedBytesFile(b, f.name));
      }

      final id = await api.createPortfolio(
        categoryId: _selected!.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(), // 空は送らないが今回は非空確定
        link: _nullIfEmpty(_linkCtrl.text),
        thumbnailFile: _thumbnailFile, // ← サムネ（必須）

        // 機械系（空は送らない）
        purpose: _nullIfEmpty(_purposeCtrl.text),
        basicSpec: _nullIfEmpty(_basicSpecCtrl.text),
        designUrl: _nullIfEmpty(_designUrlCtrl.text),
        designDescription: _nullIfEmpty(_designDescCtrl.text),
        partsList: _nullIfEmpty(_partsListCtrl.text),
        processingMethod: _nullIfEmpty(_processingMethodCtrl.text),
        processingNotes: _nullIfEmpty(_processingNotesCtrl.text),
        analysisMethod: _nullIfEmpty(_analysisMethodCtrl.text),
        analysisResult: _nullIfEmpty(_analysisResultCtrl.text),
        developmentPeriod: _nullIfEmpty(_developmentPeriodCtrl.text),
        mechanicalNotes: _nullIfEmpty(_mechanicalNotesCtrl.text),
        referenceLinks: _nullIfEmpty(_referenceLinksCtrl.text),
        toolUsed: _nullIfEmpty(_toolUsedCtrl.text),
        materialUsed: _nullIfEmpty(_materialUsedCtrl.text),

        // プログラミング
        githubUrl: _nullIfEmpty(_githubUrlCtrl.text),

        // 化学
        experimentSummary: _nullIfEmpty(_experimentSummaryCtrl.text),

        // PDF
        drawingPdf: drawing,
        supplementPdfs: supps,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿しました（ID: $id）')),
      );

      // === 黒画面対策：戻り先があるなら pop、無ければホームへ ===
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _nullIfEmpty(String s) {
    final v = s.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final slug = _selected?.slug;

    return Scaffold(
      appBar: AppBar(title: const Text('新規投稿')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Category>(
                    initialValue: _selected, // ← deprecated な value を使わず initialValue
                    decoration: const InputDecoration(labelText: 'ジャンル（カテゴリ）'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selected = c),
                  ),
                  const SizedBox(height: 12),

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

                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
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
                              child: Image.file(
                                _thumbnailFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _linkCtrl,
                    decoration: const InputDecoration(labelText: '関連リンク（任意）'),
                  ),

                  const SizedBox(height: 24),

                  if (slug == 'mechanical') _buildMechanicalFields(),
                  if (slug == 'programming') _buildProgrammingFields(),
                  if (slug == 'chemistry') _buildChemistryFields(),

                  const SizedBox(height: 24),

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
                          ..._supplementPdfs.map(
                            (f) => Text('・${f.name}', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('投稿する'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            if (_submitting) const PositionedFillOverlay(),
          ],
        ),
      ),
    );
  }

  // ====== カテゴリ別UI ======
  Widget _buildMechanicalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildProgrammingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💻 プログラミング', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _Labeled(label: 'GitHub URL（github_url）', child: TextField(controller: _githubUrlCtrl)),
        _Labeled(label: '使用言語・スタック（任意）', child: _multiline(TextEditingController())),
      ],
    );
  }

  Widget _buildChemistryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🧪 化学', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _Labeled(label: '実験の概要（experiment_summary）', child: _multiline(_experimentSummaryCtrl, min: 3)),
        _Labeled(label: '考察・結果（analysis_result 等）', child: _multiline(_analysisResultCtrl, min: 3)),
      ],
    );
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

// ローディング用オーバーレイ
class PositionedFillOverlay extends StatelessWidget {
  const PositionedFillOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(
        color: Color(0x66000000),
        child: Center(child: CircularProgressIndicator()),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
