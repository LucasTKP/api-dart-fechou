import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class ListarQuadrosEntrada {
  final String organizacaoId;

  const ListarQuadrosEntrada({required this.organizacaoId});
}

class CadastrarQuadroEntrada {
  final String organizacaoId;
  final String nome;
  final String? descricao;
  final String cor;

  const CadastrarQuadroEntrada({
    required this.organizacaoId,
    required this.nome,
    required this.descricao,
    required this.cor,
  });
}

abstract final class QuadroSchema {
  static final listar = z.inferType<ListarQuadrosEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarQuadrosEntrada(organizacaoId: json['organizacao_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarQuadroEntrada>(
    mapSchema: z.map({
      'organizacao_id':
          CamposSchema.textoObrigatorio('organizacao_id é obrigatório.'),
      'nome': CamposSchema.textoObrigatorio('Nome do quadro é obrigatório.'),
      'descricao': z.string().nullish(),
      'cor': CamposSchema.cor('roxo'),
    }),
    fromMap: (json) => CadastrarQuadroEntrada(
      organizacaoId: json['organizacao_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      cor: json['cor'] as String,
    ),
  );
}
