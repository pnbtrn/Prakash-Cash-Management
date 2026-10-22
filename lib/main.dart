class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Pre-configured accounts based on AppSheet Schema
  final List<Account> _accounts = [
    Account(categoryName: "Cash Account", group: "Cash", initialBalance: 5000),
    Account(categoryName: "PNB0208", group: "Bank", initialBalance: 25000),
    Account(categoryName: "Paytm Wallet", group: "Wallet", initialBalance: 1500),
    Account(categoryName: "Party Ram", group: "Party", initialBalance: 0),
    Account(categoryName: "Party Shyam", group: "Party", initialBalance: 0),
  ];

  final List<TransactionRecord> _transactions = [];

  // Aggregated Balance Calculations (From AppSheet Formulas)
  double get totalCashBalance => _calculateGroupBalance("Cash");
  double get totalBankBalance => _calculateGroupBalance("Bank");
  double get totalWalletBalance => _calculateGroupBalance("Wallet");

  double _calculateGroupBalance(String group) {
    double initial = _accounts
        .where((a) => a.group == group)
        .fold(0.0, (sum, item) => sum + item.initialBalance);

    var groupAccounts = _accounts
        .where((a) => a.group == group)
        .map((a) => a.categoryName)
        .toSet();

    double incoming = _transactions
        .where((t) => groupAccounts.contains(t.toAccount))
        .fold(0.0, (sum, item) => sum + item.amount);

    double outgoing = _transactions
        .where((t) => groupAccounts.contains(t.fromAccount))
        .fold(0.0, (sum, item) => sum + item.amount);

    return initial + incoming - outgoing;
  }

  double get netBalance =>
      totalCashBalance + totalBankBalance + totalWalletBalance;

  void _addTransaction(TransactionRecord txn) {
    setState(() {
      _transactions.insert(0, txn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'hi_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prakash Cash Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Net Balance Card
            Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Net Balance',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(netBalance),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _balanceItem("Cash", totalCashBalance, currencyFormat),
                        _balanceItem("Bank", totalBankBalance, currencyFormat),
                        _balanceItem("Wallet", totalWalletBalance, currencyFormat),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Transactions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            _transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("No transactions recorded yet")),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final item = _transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(item.txnType[0]),
                        ),
                        title: Text(item.detail.isEmpty
                            ? item.txnType
                            : item.detail),
                        subtitle: Text(
                            "${DateFormat('dd-MM-yyyy').format(item.date)} | ${item.fromAccount} ➔ ${item.toAccount}"),
                        trailing: Text(
                          currencyFormat.format(item.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddTransactionScreen(accounts: _accounts)),
          );
          if (result != null && result is TransactionRecord) {
            _addTransaction(result);
          }
        },
        label: const Text("New Txn"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _balanceItem(
      String title, double amount, NumberFormat currencyFormat) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(currencyFormat.format(amount),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ----------------- ENTRY SCREEN -----------------

class AddTransactionScreen extends StatefulWidget {
  final List<Account> accounts;
  const AddTransactionScreen({super.key, required this.accounts});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedTxnType = "Expense";
  String _detail = "";
  double _amount = 0.0;
  String? _fromAccount;
  String? _toAccount;
  String _paymentMethod = "Cash";

  final List<String> _txnTypes = [
    "Expense",
    "Income",
    "Payment",
    "Receipt",
    "Transfer"
  ];
  final List<String> _paymentMethods = [
    "Cash",
    "Phonepe",
    "Account",
    "Gpay",
    "Paytm",
    "Net Banking"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _fromAccount = widget.accounts.first.categoryName;
      _toAccount = widget.accounts.first.categoryName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountNames =
        widget.accounts.map((a) => a.categoryName).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTxnType,
                decoration: const InputDecoration(labelText: "Transaction Type"),
                items: _txnTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTxnType = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? "Enter valid amount"
                        : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Detail / Description"),
                onSaved: (val) => _detail = val ?? "",
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _fromAccount,
                decoration: const InputDecoration(labelText: "From Account"),
                items: accountNames
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) => setState(() => _fromAccount = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _toAccount,
                decoration: const InputDecoration(labelText: "To Account"),
                items: accountNames
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) => setState(() => _toAccount = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: "Payment Method"),
                items: _paymentMethods
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newRecord = TransactionRecord(
                      txnId: DateFormat('ddMMyyHHmmss').format(DateTime.now()),
                      date: DateTime.now(),
                      txnType: _selectedTxnType,
                      category: "General",
                      detail: _detail,
                      amount: _amount,
                      fromAccount: _fromAccount ?? "",
                      toAccount: _toAccount ?? "",
                      paymentMethod: _paymentMethod,
                    );
                    Navigator.pop(context, newRecord);
                  }
                },
                child: const Text("Save Transaction"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
