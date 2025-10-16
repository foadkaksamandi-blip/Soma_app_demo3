import 'package:flutter/material.dart';
import 'screens/seller_home_page.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: const AppBarTheme(foregroundColor: Colors.white, backgroundColor: Colors.green),
      ),
      home: const SellerHomePage(),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
    );
  }
}
