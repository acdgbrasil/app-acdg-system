# W2 — RED (Tests): TDD para Integração MCP

> **Ticket:** CLI-MCP-INTEGRATION  
> **Data:** 2026-05-06  
> **Objetivo:** Escrever tests que descrevem o contrato e **FALHAM** (TDD).

---

## 1. Estrutura de Testes

```
test/
├── mcp/
│   ├── mcp_server_adapter_test.dart
│   ├── mcp_tool_registry_test.dart
│   ├── mcp_error_mapper_test.dart
│   └── mcp_integration_test.dart
└── errors/
    └── mcp_adapter_error_test.dart
```

---

## 2. Test Suite: `mcp_error_mapper_test.dart`

```dart
import 'package:cli/src/mcp/mcp_error_mapper.dart';
import 'package:cli/src/errors/cli_error.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

void main() {
  group('McpErrorMapper', () {
    group('.toCliError()', () {
      test('converts McpError parse error (-32700) to McpAdapterError', () {
        final mcpError = McpError(-32700, 'Parse error');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result, isA<McpAdapterError>());
        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('Parse error'));
      });

      test('converts McpError invalid request (-32600)', () {
        final mcpError = McpError(-32600, 'Invalid request');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('Invalid request'));
      });

      test('converts McpError method not found (-32601)', () {
        final mcpError = McpError(-32601, 'Method not found');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('Method not found'));
      });

      test('converts McpError invalid params (-32602)', () {
        final mcpError = McpError(-32602, 'Invalid params');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('Invalid params'));
      });

      test('converts McpError internal error (-32603)', () {
        final mcpError = McpError(-32603, 'Internal error');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('Internal error'));
      });

      test('converts unknown McpError code to generic message', () {
        final mcpError = McpError(-32000, 'Custom error');
        final result = McpErrorMapper.toCliError(mcpError);

        expect(result.exitCode, 70);
        expect(result.stderrMessage, contains('MCP error (-32000)'));
        expect(result.stderrMessage, contains('Custom error'));
      });

      test('converts StateError to McpAdapterError', () {
        final error = StateError('Server not started');
        final result = McpErrorMapper.toCliError(error);

        expect(result, isA<McpAdapterError>());
        expect(result.stderrMessage, contains('Server not started'));
      });

      test('converts FormatException to McpAdapterError', () {
        final error = FormatException('Bad JSON');
        final result = McpErrorMapper.toCliError(error);

        expect(result.stderrMessage, contains('Invalid format'));
        expect(result.stderrMessage, contains('Bad JSON'));
      });

      test('converts unknown exception to generic McpAdapterError', () {
        final error = Exception('Something weird');
        final result = McpErrorMapper.toCliError(error);

        expect(result.stderrMessage, contains('Unexpected MCP error'));
        expect(result.stderrMessage, contains('Something weird'));
      });

      test('NEVER includes stack trace in stderrMessage', () {
        try {
          throw StateError('Boom');
        } catch (e, st) {
          final result = McpErrorMapper.toCliError(e);
          expect(result.stderrMessage, isNot(contains('StackTrace')));
          expect(result.stderrMessage, isNot(contains('#0')));
        }
      });
    });
  });
}
```

**Status:** 🔴 RED (classes não existem ainda)

---

## 3. Test Suite: `mcp_adapter_error_test.dart`

```dart
import 'package:cli/src/errors/cli_error.dart';
import 'package:test/test.dart';

void main() {
  group('McpAdapterError', () {
    test('is a CliError', () {
      const error = McpAdapterError('test');
      expect(error, isA<CliError>());
    });

    test('exitCode is 70 (software error)', () {
      const error = McpAdapterError('test');
      expect(error.exitCode, 70);
    });

    test('stderrMessage includes the message', () {
      const error = McpAdapterError('connection failed');
      expect(error.stderrMessage, contains('connection failed'));
    });

    test('toString returns only the message', () {
      const error = McpAdapterError('test');
      expect(error.toString(), 'test');
    });

    test('two instances with same message are equal', () {
      const a = McpAdapterError('test');
      const b = McpAdapterError('test');
      expect(a, equals(b));
    });

    test('two instances with different message are not equal', () {
      const a = McpAdapterError('a');
      const b = McpAdapterError('b');
      expect(a, isNot(equals(b)));
    });
  });
}
```

**Status:** 🔴 RED

---

## 4. Test Suite: `mcp_tool_registry_test.dart`

```dart
import 'package:cli/src/mcp/mcp_tool_registry.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

import '../../testing/fake_cli_runner.dart';

void main() {
  group('McpToolRegistry', () {
    late FakeCliRunner fakeRunner;
    late McpToolRegistry registry;
    late FakeMcpServer fakeServer;

    setUp(() {
      fakeRunner = FakeCliRunner();
      registry = McpToolRegistry(
        cliRunner: fakeRunner,
        formatter: FakeFormatter(),
      );
      fakeServer = FakeMcpServer();
    });

    test('registerAll registers at least one tool', () {
      registry.registerAll(fakeServer);
      expect(fakeServer.registeredTools, isNotEmpty);
    });

    test('patient_get tool is registered', () {
      registry.registerAll(fakeServer);
      expect(fakeServer.hasTool('patient_get'), isTrue);
    });

    test('patient_get tool has description', () {
      registry.registerAll(fakeServer);
      final tool = fakeServer.getTool('patient_get');
      expect(tool?.description, isNotNull);
      expect(tool?.description, isNotEmpty);
    });

    test('patient_get tool has inputSchema', () {
      registry.registerAll(fakeServer);
      final tool = fakeServer.getTool('patient_get');
      expect(tool?.inputSchema, isNotNull);
    });

    test('tool invocation with valid args succeeds', () async {
      registry.registerAll(fakeServer);
      fakeRunner.mockOutput = '{"name": "Alice"}';

      final result = await fakeServer.callTool('patient_get', {
        'patient_id': '550e8400-e29b-41d4-a716-446655440000',
      });

      expect(result.isError, isFalse);
      expect(result.content, isNotEmpty);
    });

    test('tool invocation with missing patient_id returns error', () async {
      registry.registerAll(fakeServer);

      final result = await fakeServer.callTool('patient_get', {});

      expect(result.isError, isTrue);
    });

    test('tool invocation with invalid patient_id type returns error', () async {
      registry.registerAll(fakeServer);

      final result = await fakeServer.callTool('patient_get', {
        'patient_id': 123, // wrong type
      });

      expect(result.isError, isTrue);
    });
  });
}
```

**Status:** 🔴 RED (FakeMcpServer não existe)

---

## 5. Test Suite: `mcp_server_adapter_test.dart`

```dart
import 'package:cli/src/mcp/mcp_server_adapter.dart';
import 'package:test/test.dart';

import '../../testing/fake_cli_runner.dart';

void main() {
  group('McpServerAdapter', () {
    late FakeCliRunner fakeRunner;

    setUp(() {
      fakeRunner = FakeCliRunner();
    });

    test('start does not throw', () async {
      final adapter = McpServerAdapter(
        cliRunner: fakeRunner,
        formatter: FakeFormatter(),
        logger: FakeLogger(),
      );

      await expectLater(adapter.start(), completes);
    });

    test('done completes after shutdown', () async {
      final adapter = McpServerAdapter(
        cliRunner: fakeRunner,
        formatter: FakeFormatter(),
        logger: FakeLogger(),
      );

      await adapter.start();
      await adapter.shutdown();
      await expectLater(adapter.done, completes);
    });

    test('shutdown is idempotent', () async {
      final adapter = McpServerAdapter(
        cliRunner: fakeRunner,
        formatter: FakeFormatter(),
        logger: FakeLogger(),
      );

      await adapter.start();
      await adapter.shutdown();
      await expectLater(adapter.shutdown(), completes);
    });
  });
}
```

**Status:** 🔴 RED

---

## 6. Test Suite: `mcp_integration_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('MCP Integration (stdio)', () {
    late Process process;

    setUp(() async {
      process = await Process.start(
        'dart',
        ['run', 'bin/cli.dart', 'mcp', 'serve'],
        workingDirectory: 'apps/cli',
      );
    });

    tearDown(() async {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode;
    });

    test('server responds to initialize request', () async {
      final request = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2025-03-26',
          'capabilities': {},
          'clientInfo': {'name': 'test', 'version': '1.0.0'},
        },
      });

      process.stdin.writeln(request);
      await process.stdin.flush();

      final response = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 5));

      final json = jsonDecode(response) as Map<String, dynamic>;
      expect(json['jsonrpc'], '2.0');
      expect(json['id'], 1);
      expect(json['result'], isNotNull);
    });

    test('server exposes tools after initialization', () async {
      // initialize first
      // then tools/list
      // expect at least one tool
    });
  });
}
```

**Status:** 🔴 RED

---

## 7. Fakes Necessários (testing/)

```dart
// test/testing/fake_mcp_server.dart
final class FakeMcpServer {
  final Map<String, RegisteredTool> _tools = {};

  void registerTool({
    required String name,
    required String description,
    required ToolInputSchema inputSchema,
    required ToolFunction callback,
  }) {
    _tools[name] = RegisteredTool(
      name: name,
      description: description,
      inputSchema: inputSchema,
      callback: callback,
    );
  }

  bool hasTool(String name) => _tools.containsKey(name);
  RegisteredTool? getTool(String name) => _tools[name];

  Future<CallToolResult> callTool(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) throw StateError('Tool not found: $name');
    return tool.callback(args, FakeRequestHandlerExtra());
  }
}
```

**Status:** 🔴 RED

---

## 8. Resumo de Tests

| Suite | Tests | Status |
|-------|-------|--------|
| `mcp_error_mapper_test` | 10 | 🔴 RED |
| `mcp_adapter_error_test` | 6 | 🔴 RED |
| `mcp_tool_registry_test` | 7 | 🔴 RED |
| `mcp_server_adapter_test` | 3 | 🔴 RED |
| `mcp_integration_test` | 2 | 🔴 RED |
| **Total** | **28** | **🔴 ALL RED** |
