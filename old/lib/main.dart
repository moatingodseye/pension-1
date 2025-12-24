import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pension Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String? token;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: token == null ? _buildLogin() : HomePage(token: token!),
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _login, child: Text("Login")),
        ],
      ),
    );
  }

  void _login() async {
    // print('Attempting to login with username: ${_usernameController.text} and password: ${_passwordController.text}');
    try {
      final response = await http.post(
        Uri.parse("http://192.168.101.134:8080/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() => token = jsonDecode(response.body)['token']);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed')));
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }
} 

class HomePage extends StatefulWidget {
  final String token;
  HomePage({required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<double> results = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Simulation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : _runSimulation,
              child: Text("Run Monte Carlo Simulation"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text("No data"))
                  : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSimulation() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.101.134:8080/simulate"),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => results = data.map((e) => (e as num).toDouble()).toList());
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Simulation failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 10000),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 5),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: results
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            dotData: FlDotData(show: false),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
