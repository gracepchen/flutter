import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status bar and gesture area. Screens handle insets with
  // SafeArea and MediaQuery padding.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const InvestorsEdgeApp());
}
