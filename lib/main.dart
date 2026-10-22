import 'package:flutter/material.dart';

void main() {
  runApp(const CashApp());
}

class CashApp extends StatelessWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prakash Cash Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class AccountItem {
  final String name;
  final String group;
  double balance;

  AccountItem({required this.name, required this.group, this.balance = 0.0});
}

class TxnItem {
  final String id;
  final String date;
  final String type;
  final String detail;
  final double amount;
  final String fromAcc;
  final String toAcc;

  TxnItem({
    required this.id,
    required this.date,
    required this.type,
    required this.detail,
    required this.amount,
    required this.fromAcc,
    required this.toAcc,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<AccountItem> _accounts = [
    AccountItem(name: "Cash In Hand", group: "Cash", balance: 5000),
    AccountItem(name: "PNB0208", group: "Bank", balance: 25000),
    AccountItem(name: "Paytm Wallet", group: "Wallet", balance: 1500),
    AccountItem(name: "Party Account", group: "Party", balance: 0),
  ];

  final List<TxnItem> _txns = [];

  double get cashTotal => _calcGroup("Cash");
  double get bankTotal => _calcGroup("Bank");
  double get walletTotal => _calcGroup("Wallet");
  double get netTotal => cashTotal + bankTotal + walletTotal;

  double _calcGroup(String grp) {
    double initial = _accounts
        .where((a) => a.group == grp)
        .fold(0.0, (sum, a) => sum + a.balance);

    var names = _accounts.where((a) => a.group == grp).map((a) => a.name).toSet();
    double incoming = _txns.where((t) => names.contains(t.toAcc)).fold(0.0, (sum, t) => sum + t.amount);
    double outgoing = _txns.where((t) => names.contains(t.fromAcc)).fold(0.0, (sum, t) => sum + t.amount);
    return initial + incoming - outgoing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prakash Cash Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Total Net Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('₹${netTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _col('Cash', '₹${cashTotal.toStringAsFixed(2)}'),
                        _col('Bank', '₹${bankTotal.toStringAsFixed(2)}'),
                        _col('Wallet', '₹${walletTotal.toStringAsFixed(2)}'),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_txns.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No transactions yet')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _txns.length,
                itemBuilder: (ctx, i) {
                  final item = _txns[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(item.type[0])),
                    title: Text(item.detail.isEmpty ? item.type : item.detail),
                    subtitle: Text('${item.date} | ${item.fromAcc} ➔ ${item.toAcc}'),
                    trailing: Text('₹${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => EntryPage(accounts: _accounts)),
          );
          if (res != null && res is TxnItem) {
            setState(() {
              _txns.insert(0, res);
            });
          }
        },
      ),
    );
  }

  Widget _col(String t, String v) {
    return Column(
      children: [
        Text(t, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class EntryPage extends StatefulWidget {
  final List<AccountItem> accounts;
  const EntryPage({super.key, required this.accounts});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _key = GlobalKey<FormState>();
  String _type = 'Expense';
  String _detail = '';
  double _amount = 0.0;
  String _from = 'Cash In Hand';
  String _to = 'Cash In Hand';

  final _types = ['Expense', 'Income', 'Payment', 'Receipt', 'Transfer'];

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _from = widget.accounts.first.name;
      _to = widget.accounts.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.accounts.map((a) => a.name).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _key,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid number' : null,
                onSaved: (v) => _amount = double.parse(v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Detail'),
                onSaved: (v) => _detail = v ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _from,
                decoration: const InputDecoration(labelText: 'From Account'),
                items: list.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _from = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _to,
                decoration: const InputDecoration(labelText: 'To Account'),
                items: list.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _to = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_key.currentState!.validate()) {
                    _key.currentState!.save();
                    final now = DateTime.now();
                    final item = TxnItem(
                      id: '${now.millisecondsSinceEpoch}',
                      date: '${now.day}-${now.month}-${now.year}',
                      type: _type,
                      detail: _detail,
                      amount: _amount,
                      fromAcc: _from,
                      toAcc: _to,
                    );
                    Navigator.pop(context, item);
                  }
                },
                child: const Text('Save Record'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
