import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class StatePensionScreen extends StatefulWidget {
  const StatePensionScreen({super.key});

  @override
  State<StatePensionScreen> createState() => _StatePensionScreenState();
}

class _StatePensionScreenState extends State<StatePensionScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchStatePension();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final sp = provider.statePension;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('State Pension', style: TextStyle(fontSize: 24)),
          TextField(
            controller: ageController,
            decoration: const InputDecoration(labelText: 'Start Age'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: () async {
              final age = int.tryParse(ageController.text);
              final amt = double.tryParse(amountController.text);
              if (age == null || amt == null) return;
              await provider.setStatePension({
                'start_age': age,
                'amount': amt,
                'interest_rate': 0.02,
              });
              ageController.clear();
              amountController.clear();
            },
            child: const Text('Save State Pension'),
          ),
          if (sp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Current: £${sp['amount']} at age ${sp['start_age']}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }
}
