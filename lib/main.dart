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
      child: const QReportApp(),
    ),
  );
}

class QReportApp extends StatelessWidget {
  const QReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QReport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF184673)),
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
