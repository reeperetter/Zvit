import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  runApp(
    ChangeNotifierProvider.value(
      value: storage,
      child: const ZvitApp(),
    ),
  );
}

class ZvitApp extends StatelessWidget {
  const ZvitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zvit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4965)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
