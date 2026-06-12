import 'package:kanban_api/core/schemas/campos_schema.dart';
import 'package:zard/zard.dart';

class ListarCartoesEntrada {
  final String quadroId;

  const ListarCartoesEntrada({required this.quadroId});
}

class CadastrarCartaoEntrada {
  final String quadroId;
  final String colunaId;
  final String titulo;
  final String clienteId;
  final String? observacao;
  final String? responsavelId;
  final int? valorProposta;

  const CadastrarCartaoEntrada({
    required this.quadroId,
    required this.colunaId,
    required this.titulo,
    required this.clienteId,
    required this.observacao,
    required this.responsavelId,
    required this.valorProposta,
  });
}

class AtualizarCartaoEntrada {
  final String colunaId;
  final String titulo;
  final String clienteId;
  final String? observacao;
  final String? responsavelId;
  final int? valorProposta;

  const AtualizarCartaoEntrada({
    required this.colunaId,
    required this.titulo,
    required this.clienteId,
    required this.observacao,
    required this.responsavelId,
    required this.valorProposta,
  });
}

abstract final class CartaoSchema {
  static final listar = z.inferType<ListarCartoesEntrada>(
    mapSchema: z.map({
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
    }),
    fromMap: (json) =>
        ListarCartoesEntrada(quadroId: json['quadro_id'] as String),
  );

  static final cadastrar = z.inferType<CadastrarCartaoEntrada>(
    mapSchema: z.map({
      'quadro_id': CamposSchema.textoObrigatorio('quadro_id é obrigatório.'),
      'coluna_id': CamposSchema.textoObrigatorio('coluna_id é obrigatório.'),
      'titulo': CamposSchema.textoObrigatorio('Título do cartão é obrigatório.'),
      'cliente_id':
          CamposSchema.textoObrigatorio('Cliente do cartão é obrigatório.'),
      'observacao': z.string().nullish(),
      'responsavel_id': z.string().nullish(),
      'valor_proposta': z.int().nullish(),
    }),
    fromMap: (json) => CadastrarCartaoEntrada(
      quadroId: json['quadro_id'] as String,
      colunaId: json['coluna_id'] as String,
      titulo: json['titulo'] as String,
      clienteId: json['cliente_id'] as String,
      observacao: json['observacao'] as String?,
      responsavelId: json['responsavel_id'] as String?,
      valorProposta: json['valor_proposta'] as int?,
    ),
  );

  static final atualizar = z.inferType<AtualizarCartaoEntrada>(
    mapSchema: z.map({
      'coluna_id': CamposSchema.textoObrigatorio('coluna_id é obrigatório.'),
      'titulo': CamposSchema.textoObrigatorio('Título do cartão é obrigatório.'),
      'cliente_id':
          CamposSchema.textoObrigatorio('Cliente do cartão é obrigatório.'),
      'observacao': z.string().nullish(),
      'responsavel_id': z.string().nullish(),
      'valor_proposta': z.int().nullish(),
    }),
    fromMap: (json) => AtualizarCartaoEntrada(
      colunaId: json['coluna_id'] as String,
      titulo: json['titulo'] as String,
      clienteId: json['cliente_id'] as String,
      observacao: json['observacao'] as String?,
      responsavelId: json['responsavel_id'] as String?,
      valorProposta: json['valor_proposta'] as int?,
    ),
  );
}
