import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class CadastrarUsuarioEntrada {
  final String nome;
  final String email;

  const CadastrarUsuarioEntrada({
    required this.nome,
    required this.email,
  });
}

abstract final class UsuarioSchema {
  static final cadastrar = z.inferType<CadastrarUsuarioEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('O nome é obrigatório.'),
      'email': z
          .string(message: 'O e-mail é obrigatório.')
          .email(message: 'E-mail inválido.'),
    }),
    fromMap: (json) => CadastrarUsuarioEntrada(
      nome: json['nome'] as String,
      email: json['email'] as String,
    ),
  );
}
