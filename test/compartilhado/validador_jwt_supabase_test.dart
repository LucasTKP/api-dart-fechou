import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:kanban_api/compartilhado/validador_jwt_supabase.dart';
import 'package:test/test.dart';

void main() {
  const jwtSecret = 'test-jwt-secret-com-pelo-menos-32-chars';
  const supabaseUrl = 'https://projeto-teste.supabase.co';
  const usuarioId = '7eaa284f-ad2e-4f41-96fe-e3d67177cb7c';

  late ValidadorJwtSupabase validador;

  setUp(() {
    validador = ValidadorJwtSupabase(
      jwtSecret: jwtSecret,
      supabaseUrl: supabaseUrl,
    );
  });

  String gerarToken({
    String? sub,
    String role = 'authenticated',
    String aud = 'authenticated',
    DateTime? expiresAt,
  }) {
    final jwt = JWT(
      {
        'sub': sub ?? usuarioId,
        'role': role,
        'aud': aud,
      },
      issuer: '$supabaseUrl/auth/v1',
    );

    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: expiresAt?.difference(DateTime.now().toUtc()),
    );
  }

  group('ValidadorJwtSupabase', () {
    test('extrai usuarioId de token válido', () {
      final token = gerarToken(expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)));

      expect(validador.extrairUsuarioId(token), usuarioId);
    });

    test('rejeita token com assinatura inválida', () {
      final token = gerarToken(expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)));

      final validadorErrado = ValidadorJwtSupabase(
        jwtSecret: 'outro-secret-totalmente-diferente-32c',
        supabaseUrl: supabaseUrl,
      );

      expect(validadorErrado.extrairUsuarioId(token), isNull);
    });

    test('rejeita token expirado', () {
      final token = gerarToken(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );

      expect(validador.extrairUsuarioId(token), isNull);
    });

    test('rejeita token com role diferente de authenticated', () {
      final token = gerarToken(
        role: 'service_role',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(validador.extrairUsuarioId(token), isNull);
    });

    test('rejeita token sem sub', () {
      final jwt = JWT(
        {
          'role': 'authenticated',
          'aud': 'authenticated',
        },
        issuer: '$supabaseUrl/auth/v1',
      );

      final token = jwt.sign(
        SecretKey(jwtSecret),
        expiresIn: const Duration(hours: 1),
      );

      expect(validador.extrairUsuarioId(token), isNull);
    });
  });
}
