import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Valida localmente JWTs emitidos pelo Supabase Auth (HS256).
///
/// Evita a chamada remota `auth.getUser(jwt)` em cada requisição.
class ValidadorJwtSupabase {
  ValidadorJwtSupabase({
    required String jwtSecret,
    required String supabaseUrl,
  })  : _secretKey = SecretKey(jwtSecret),
        _issuer = _normalizarIssuer(supabaseUrl);

  final SecretKey _secretKey;
  final String _issuer;

  /// Retorna o `sub` (id do usuário) se o token for válido; caso contrário `null`.
  String? extrairUsuarioId(String token) {
    try {
      final jwt = JWT.verify(
        token,
        _secretKey,
        issuer: _issuer,
        audience: Audience(['authenticated']),
      );

      final payload = jwt.payload;
      if (payload is! Map<String, dynamic>) return null;

      final sub = payload['sub'];
      if (sub is! String || sub.isEmpty) return null;

      final role = payload['role'];
      if (role != 'authenticated') return null;

      return sub;
    } on JWTException {
      return null;
    }
  }

  static String _normalizarIssuer(String supabaseUrl) {
    final base = supabaseUrl.endsWith('/')
        ? supabaseUrl.substring(0, supabaseUrl.length - 1)
        : supabaseUrl;

    return '$base/auth/v1';
  }
}
