import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class PensionPotsScreen extends StatefulWidget {
  const PensionPotsScreen({super.key});

  @override
  State<PensionPotsScreen> createState() => _PensionPotsScreenState();
}

class _PensionPotsScreenState extends State<PensionPotsScreen> {
  final TextEditingController amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchPensionPots();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Pension Pots', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.pensionPots.length,
              itemBuilder: (ctx, i) {
                final pot = provider.pensionPots[i];
                return ListTile(
                  title: Text('£${pot['amount']}'),
                  subtitle: Text(pot['date']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      provider.deletePensionPot(pot['id'] as int);
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
            onPressed: () => _pickDate(context),
            child: const Text('Pick Date'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text);
              if (amt == null) return;
              provider.addPensionPot({
                'amount': amt,
                'date': selectedDate.toIso8601String(),
                'interest_rate': 0.03
              });
              amountController.clear();
            },
            child: const Text('Add Pension Pot'),
          ),
        ],
      ),
    );
  }
}
