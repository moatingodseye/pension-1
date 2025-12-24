import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class PensionPotsScreen extends StatefulWidget {
  const PensionPotsScreen({super.key});

  @override
  State<PensionPotsScreen> createState() => _PensionPotsScreenState();
}

class _PensionPotsScreenState extends State<PensionPotsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController interestController = TextEditingController();

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchPensionPots();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = picked.toIso8601String().split('T')[0];
      });
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
                  subtitle: Text(
                      'Date: ${pot['date']}  |  Rate: ${pot['interest_rate']}'),
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
          const Divider(),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (£)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(context),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select date' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: interestController,
                  decoration:
                      const InputDecoration(labelText: 'Interest Rate (%)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter interest rate' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final amount = double.tryParse(amountController.text);
                    final rate = double.tryParse(interestController.text);

                    if (amount == null || rate == null || selectedDate == null) {
                      return;
                    }

                    await provider.addPensionPot({
                      'amount': amount,
                      'date': selectedDate!.toIso8601String(),
                      'interest_rate': rate / 100,
                    });

                    amountController.clear();
                    dateController.clear();
                    interestController.clear();
                    selectedDate = null;
                  },
                  child: const Text('Add Pension Pot'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
