import 'package:flutter/material.dart';
import 'root.dart';

void main() {
  // Ensure Flutter bindings are initialized before any core setup
  WidgetsFlutterBinding.ensureInitialized();

  // Run the Root widget which handles app-wide configuration
  runApp(const Root());
}
