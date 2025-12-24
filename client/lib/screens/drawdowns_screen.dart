import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class DrawdownsScreen extends StatefulWidget {
  const DrawdownsScreen({super.key});

  @override
  State<DrawdownsScreen> createState() => _DrawdownsScreenState();
}

class _DrawdownsScreenState extends State<DrawdownsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController interestController = TextEditingController();

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchDrawdowns();
  }

  Future<void> _pickDate(
      BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
          startDateController.text =
              picked.toIso8601String().split('T')[0];
        } else {
          selectedEndDate = picked;
          endDateController.text =
              picked.toIso8601String().split('T')[0];
        }
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
          const Text('Drawdowns', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.drawdowns.length,
              itemBuilder: (ctx, i) {
                final d = provider.drawdowns[i];
                return ListTile(
                  title: Text('£${d['amount']}'),
                  subtitle: Text(
                      '${d['start_date']} → ${d['end_date']} at ${d['interest_rate']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        provider.deleteDrawdown(d['id'] as int),
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
                  decoration:
                      const InputDecoration(labelText: 'Amount (£)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty
                          ? 'Enter amount'
                          : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(context, true),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Select start date'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(context, false),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Select end date'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: interestController,
                  decoration: const InputDecoration(
                      labelText: 'Interest Rate (%)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty
                          ? 'Enter interest rate'
                          : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    final amount =
                        double.tryParse(amountController.text);
                    final rate =
                        double.tryParse(interestController.text);
                    if (amount == null ||
                        rate == null ||
                        selectedStartDate == null ||
                        selectedEndDate == null) return;

                    provider.addDrawdown({
                      'amount': amount,
                      'start_date':
                          selectedStartDate!.toIso8601String(),
                      'end_date':
                          selectedEndDate!.toIso8601String(),
                      'interest_rate': rate / 100,
                    });

                    amountController.clear();
                    startDateController.clear();
                    endDateController.clear();
                    interestController.clear();
                    selectedStartDate = null;
                    selectedEndDate = null;
                  },
                  child: const Text('Add Drawdown'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
