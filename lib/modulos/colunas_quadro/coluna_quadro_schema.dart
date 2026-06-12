import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class ListarColunasEntrada {
  final String quadroId;

  const ListarColunasEntrada({required this.quadroId});
}

class CadastrarColunaEntrada {
  final String quadroId;
  final String nome;
  final String cor;

  const CadastrarColunaEntrada({
    required this.quadroId,
    required this.nome,
    required this.cor,
  });
}

class AtualizarColunaEntrada {
  final String nome;
  final String cor;

  const AtualizarColunaEntrada({
    required this.nome,
    required this.cor,
  });
}

class ReordenarColunasEntrada {
  final String quadroId;
  final List<String> colunaIds;

  const ReordenarColunasEntrada({
    required this.quadroId,
    required this.colunaIds,
  });
}

abstract final class ColunaQuadroSchema {
  static final listar = z.inferType<ListarColunasEntrada>(
    mapSchema: z.map({
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarColunasEntrada(quadroId: json['quadro_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarColunaEntrada>(
    mapSchema: z.map({
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
      'nome': CamposSchema.textoObrigatorio('Nome da coluna é obrigatório.'),
      'cor': CamposSchema.cor('cinza'),
    }),
    fromMap: (json) => CadastrarColunaEntrada(
      quadroId: json['quadro_id'] as String,
      nome: json['nome'] as String,
      cor: json['cor'] as String,
    ),
  );

  static final atualizar = z.inferType<AtualizarColunaEntrada>(
    mapSchema: z.map({
      'nome': CamposSchema.textoObrigatorio('Nome da coluna é obrigatório.'),
      'cor': CamposSchema.cor('cinza'),
    }),
    fromMap: (json) => AtualizarColunaEntrada(
      nome: json['nome'] as String,
      cor: json['cor'] as String,
    ),
  );

  static final reordenar = z.inferType<ReordenarColunasEntrada>(
    mapSchema: z.map({
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
      'coluna_ids': z.list(
        z.string(message: 'coluna_ids deve conter apenas IDs.'),
        message: 'coluna_ids é obrigatório.',
      ),
    }),
    fromMap: (json) => ReordenarColunasEntrada(
      quadroId: json['quadro_id'] as String,
      colunaIds: List<String>.from(json['coluna_ids'] as List),
    ),
  );
}
