import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class CadastrarOrganizacaoEntrada {
  final String nome;

  const CadastrarOrganizacaoEntrada({required this.nome});
}

class AtualizarOrganizacaoEntrada {
  final String nome;

  const AtualizarOrganizacaoEntrada({required this.nome});
}

class ListarMembrosEntrada {
  final String organizacaoId;

  const ListarMembrosEntrada({required this.organizacaoId});
}

abstract final class OrganizacaoSchema {
  static final cadastrar = z.inferType<CadastrarOrganizacaoEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('Nome da organização é obrigatório.'),
    }),
    fromMap: (json) => CadastrarOrganizacaoEntrada(nome: json['nome'] as String),
  );

  static final atualizar = z.inferType<AtualizarOrganizacaoEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('Nome da organização é obrigatório.'),
    }),
    fromMap: (json) => AtualizarOrganizacaoEntrada(nome: json['nome'] as String),
  );

  static final listarMembros = z.inferType<ListarMembrosEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarMembrosEntrada(organizacaoId: json['organizacao_id'] as String),
  );
}
