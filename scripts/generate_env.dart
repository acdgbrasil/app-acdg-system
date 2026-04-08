import 'dart:io';
import 'package:yaml/yaml.dart';

/// Script to generate .env files from a master secrets/env/env.yaml file.
///
/// Usage: dart scripts/generate_env.dart [environment]
/// Example: dart scripts/generate_env.dart development
void main(List<String> args) {
  final yamlFile = File('secrets/env/env.yaml');
  if (!yamlFile.existsSync()) {
    stderr.writeln('Error: secrets/env/env.yaml not found.');
    exit(1);
  }

  final targetEnv = args.isNotEmpty ? args[0] : 'development';
  final yamlString = yamlFile.readAsStringSync();
  final yamlDoc = loadYaml(yamlString) as YamlMap;

  final environments = yamlDoc['environments'] as YamlMap;
  if (!environments.containsKey(targetEnv)) {
    stderr.writeln('Error: Environment "$targetEnv" not found in env.yaml.');
    stderr.writeln('Available environments: ${environments.keys.join(', ')}');
    exit(1);
  }

  final config = environments[targetEnv];
  final buffer = StringBuffer();

  if (config is Map) {
    config.forEach((key, value) {
      if (key == '<<') {
        if (value is Map) {
          value.forEach((k, v) => buffer.writeln('$k=$v'));
        }
      } else {
        buffer.writeln('$key=$value');
      }
    });
  }

  // Output to the app directory
  final outputFile = File('apps/acdg_system/.env');
  outputFile.writeAsStringSync(buffer.toString());

  stdout.writeln('Successfully generated apps/acdg_system/.env for "$targetEnv"');
}
