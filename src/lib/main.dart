import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizTown Rent-Manager',
      theme: ThemeData(useMaterial3: true),
      // Placeholder — màn hình thật (S-00..S-05, L-01..L-19, T-01..T-11) chờ design final.
      home: const _PendingDesignScreen(),
    );
  }
}

class _PendingDesignScreen extends StatelessWidget {
  const _PendingDesignScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('BizTown Rent-Manager — waiting for final design')),
    );
  }
}
