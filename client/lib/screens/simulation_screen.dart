import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/chart_widget.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ElevatedButton(
          onPressed: () => Provider.of<DataProvider>(context, listen: false).simulate(),
          child: const Text('Run Simulation')),
      Expanded(
        child: Consumer<DataProvider>(
          builder: (context, provider, _) {
            if (provider.simulationResults.isEmpty) {
              return const Text('No data');
            }
            return SimulationChart(data: provider.simulationResults);
          },
        ),
      ),
    ]);
  }
}
