import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final users = provider.users;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Admin Users', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, i) {
                final u = users[i];
                return ListTile(
                  title: Text(u['username']),
                  subtitle:
                      Text(u['locked'] == 1 ? 'Status: Locked' : 'Status: Active'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lock),
                        onPressed: () async {
                          await provider.lockUser(u['id'] as int);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          await provider.resetUserPassword(u['id'] as int, 'password123');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
