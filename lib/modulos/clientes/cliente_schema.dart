import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class ListarClientesEntrada {
  final String organizacaoId;

  const ListarClientesEntrada({required this.organizacaoId});
}

class CadastrarClienteEntrada {
  final String organizacaoId;
  final String nome;
  final String? email;
  final String? telefone;
  final String? empresa;

  const CadastrarClienteEntrada({
    required this.organizacaoId,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.empresa,
  });
}

class AtualizarClienteEntrada {
  final String nome;
  final String? email;
  final String? telefone;
  final String? empresa;

  const AtualizarClienteEntrada({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.empresa,
  });
}

abstract final class ClienteSchema {
  static final listar = z.inferType<ListarClientesEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarClientesEntrada(organizacaoId: json['organizacao_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarClienteEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
      'nome': CamposSchema.textoObrigatorio('Nome do cliente é obrigatório.'),
      'email': z.string().nullish(),
      'telefone': z.string().nullish(),
      'empresa': z.string().nullish(),
    }),
    fromMap: (json) => CadastrarClienteEntrada(
      organizacaoId: json['organizacao_id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      empresa: json['empresa'] as String?,
    ),
  );

  static final atualizar = z.inferType<AtualizarClienteEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('Nome do cliente é obrigatório.'),
      'email': z.string().nullish(),
      'telefone': z.string().nullish(),
      'empresa': z.string().nullish(),
    }),
    fromMap: (json) => AtualizarClienteEntrada(
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      empresa: json['empresa'] as String?,
    ),
  );
}
