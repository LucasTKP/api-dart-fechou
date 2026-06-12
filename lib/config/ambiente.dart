import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';

/// Variáveis de ambiente e cliente Supabase (server-side).
abstract final class Ambiente {
  static final DotEnv _env = DotEnv();
  static SupabaseClient? _supabase;
  static bool _carregado = false;

  static void carregar() {
    if (_carregado) return;

    if (File('.env').existsSync()) {
      _env.load();
    }

    _carregado = true;
  }

  static String _ler(String chave, {List<String> alternativas = const []}) {
    carregar();

    final valorSistema = Platform.environment[chave];
    if (valorSistema != null && valorSistema.isNotEmpty) {
      return valorSistema;
    }

    final valorArquivo = _env[chave];
    if (valorArquivo != null && valorArquivo.isNotEmpty) {
      return valorArquivo;
    }

    for (final alternativa in alternativas) {
      final valorAlternativoSistema = Platform.environment[alternativa];
      if (valorAlternativoSistema != null && valorAlternativoSistema.isNotEmpty) {
        return valorAlternativoSistema;
      }

      final valorAlternativoArquivo = _env[alternativa];
      if (valorAlternativoArquivo != null && valorAlternativoArquivo.isNotEmpty) {
        return valorAlternativoArquivo;
      }
    }

    throw StateError('$chave não configurada.');
  }

  static String get supabaseUrl => _ler('SUPABASE_URL');

  /// Chave secreta do Supabase (`sb_secret_...`).
  /// Aceita `SUPABASE_SECRET_KEY` (novo padrão) ou
  /// `SUPABASE_SERVICE_ROLE_KEY` (legado).
  static String get supabaseSecretKey => _ler(
    'SUPABASE_SECRET_KEY',
    alternativas: ['SUPABASE_SERVICE_ROLE_KEY'],
  );

  /// Segredo usado pelo Supabase Auth para assinar JWTs (HS256).
  /// Dashboard: Project Settings > API > JWT Secret.
  static String get supabaseJwtSecret => _ler('SUPABASE_JWT_SECRET');

  static int get porta {
    carregar();

    final valor = Platform.environment['PORT'] ?? _env['PORT'];
    return int.tryParse(valor ?? '') ?? 8080;
  }

  /// URL base do WPPConnect Server (ex.: `http://localhost:21465`).
  static String get wppconnectBaseUrl {
    carregar();

    final valor =
        Platform.environment['WPPCONNECT_BASE_URL'] ?? _env['WPPCONNECT_BASE_URL'];
    final base = (valor == null || valor.isEmpty)
        ? 'http://localhost:21465'
        : valor;

    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  /// Chave secreta do WPPConnect (`SECRET_KEY` do config do servidor).
  ///
  /// Fica **apenas** no servidor; nunca é enviada ao frontend.
  static String get wppconnectSecretKey => _ler('WPPCONNECT_SECRET_KEY');

  /// URL do webhook desta API que o WPPConnect deve chamar ao iniciar a sessão.
  static String get whatsappWebhookUrl {
    carregar();

    final valor = Platform.environment['KANBAN_API_WEBHOOK_URL'] ??
        _env['KANBAN_API_WEBHOOK_URL'];

    if (valor == null || valor.isEmpty) {
      return 'http://localhost:8080/webhook/whatsapp';
    }

    return valor;
  }

  static SupabaseClient get supabase {
    return _supabase ??= SupabaseClient(supabaseUrl, supabaseSecretKey);
  }
}
