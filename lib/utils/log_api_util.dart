import 'dart:io';

/// Logs padronizados de erros da API no terminal.
abstract final class LogApiUtil {
  static void erro({
    required String tipo,
    required Object erro,
    StackTrace? stackTrace,
    int? statusCode,
  }) {
    final linhas = <String>[
      '[ERRO API] $tipo${statusCode != null ? ' (HTTP $statusCode)' : ''}',
      '  Problema: $erro',
    ];

    if (stackTrace != null) {
      linhas
        ..add('  Stack trace:')
        ..add(stackTrace.toString());
    }

    stderr.writeln(linhas.join('\n'));
  }
}
