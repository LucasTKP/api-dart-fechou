import 'package:equatable/equatable.dart';

/// Retorno da RPC executar_captacao_automatica.
class ResultadoCaptacaoAutomaticaEntity extends Equatable {
  const ResultadoCaptacaoAutomaticaEntity({
    required this.regraId,
    required this.clienteId,
    required this.cartaoId,
    required this.clienteCriado,
    required this.cartaoCriado,
  });

  final String regraId;
  final String clienteId;
  final String cartaoId;
  final bool clienteCriado;
  final bool cartaoCriado;

  factory ResultadoCaptacaoAutomaticaEntity.fromMap(Map<String, dynamic> map) {
    return ResultadoCaptacaoAutomaticaEntity(
      regraId: map['regra_id'] as String,
      clienteId: map['cliente_id'] as String,
      cartaoId: map['cartao_id'] as String,
      clienteCriado: map['cliente_criado'] as bool,
      cartaoCriado: map['cartao_criado'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'regra_id': regraId,
    'cliente_id': clienteId,
    'cartao_id': cartaoId,
    'cliente_criado': clienteCriado,
    'cartao_criado': cartaoCriado,
  };

  @override
  List<Object?> get props => [
    regraId,
    clienteId,
    cartaoId,
    clienteCriado,
    cartaoCriado,
  ];
}
