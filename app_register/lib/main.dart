import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const App(),
    ),
  );
}
