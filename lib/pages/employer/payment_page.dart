import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _plan = 'Pro'; // Starter / Pro / Enterprise
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _exp = TextEditingController();
  final _cvc = TextEditingController();

  void _confirm() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$_plan」プランに変更しました')),
    );
    Navigator.pop(context);
  }

  Widget _planTile(String name, String price, String desc) {
    final selected = _plan == name;
    return InkWell(
      onTap: () => setState(() => _plan = name),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Colors.blueAccent : Colors.grey.shade300,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お支払い')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('プランを選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _planTile('Starter', '¥0/月', '基本機能'),
          _planTile('Pro', '¥2,000/月', '応募者管理、企業ブランディング強化'),
          _planTile('Enterprise', 'お見積り', '専任サポート・拡張機能'),

          const SizedBox(height: 20),
          const Text('カード情報',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _cardNumber,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'カード番号'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cardName,
            decoration: const InputDecoration(labelText: '名義（半角ローマ字）'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _exp,
                  decoration: const InputDecoration(labelText: '有効期限 (MM/YY)'),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cvc,
                  decoration: const InputDecoration(labelText: 'CVC'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('確定して支払う'),
          ),
        ],
      ),
    );
  }
}
