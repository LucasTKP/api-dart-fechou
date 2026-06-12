import 'package:equatable/equatable.dart';

/// Retorno enxuto da RPC buscar_regra_captacao_automatica_por_mensagem.
class RegraCaptacaoResumidaEntity extends Equatable {
  const RegraCaptacaoResumidaEntity({
    required this.id,
    required this.nome,
    required this.palavraChave,
    required this.quadroId,
    required this.colunaId,
    required this.origem,
  });

  final String id;
  final String nome;
  final String palavraChave;
  final String quadroId;
  final String colunaId;
  final String origem;

  factory RegraCaptacaoResumidaEntity.fromMap(Map<String, dynamic> map) {
    return RegraCaptacaoResumidaEntity(
      id: map['id'] as String,
      nome: map['nome'] as String,
      palavraChave: map['palavra_chave'] as String,
      quadroId: map['quadro_id'] as String,
      colunaId: map['coluna_id'] as String,
      origem: map['origem'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'palavra_chave': palavraChave,
    'quadro_id': quadroId,
    'coluna_id': colunaId,
    'origem': origem,
  };

  @override
  List<Object?> get props => [
    id,
    nome,
    palavraChave,
    quadroId,
    colunaId,
    origem,
  ];
}
