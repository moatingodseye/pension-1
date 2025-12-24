import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class DrawdownsScreen extends StatefulWidget {
  const DrawdownsScreen({super.key});

  @override
  State<DrawdownsScreen> createState() => _DrawdownsScreenState();
}

class _DrawdownsScreenState extends State<DrawdownsScreen> {
  final TextEditingController amountController = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchDrawdowns();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Drawdowns', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.drawdowns.length,
              itemBuilder: (ctx, i) {
                final d = provider.drawdowns[i];
                return ListTile(
                  title: Text('£${d['amount']}'),
                  subtitle: Text('${d['start_date']} → ${d['end_date']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      provider.deleteDrawdown(d['id'] as int);
                    },
                  ),
                );
              },
            ),
          ),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _pickStartDate(context),
            child: const Text('Pick Start Date'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _pickEndDate(context),
            child: const Text('Pick End Date'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text);
              if (amt == null) return;
              provider.addDrawdown({
                'amount': amt,
                'start_date': startDate.toIso8601String(),
                'end_date': endDate.toIso8601String(),
                'interest_rate': 0.03
              });
              amountController.clear();
            },
            child: const Text('Add Drawdown'),
          ),
        ],
      ),
    );
  }
}
