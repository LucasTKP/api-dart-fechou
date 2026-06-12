sealed class ExcecaoApi implements Exception {
  const ExcecaoApi(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

final class NaoAutenticadoException extends ExcecaoApi {
  const NaoAutenticadoException([
    super.mensagem = 'Usuário não autenticado.',
  ]);
}

final class AcessoNegadoException extends ExcecaoApi {
  const AcessoNegadoException([
    super.mensagem = 'Acesso negado.',
  ]);
}

final class RecursoNaoEncontradoException extends ExcecaoApi {
  const RecursoNaoEncontradoException([
    super.mensagem = 'Recurso não encontrado.',
  ]);
}

final class ValidacaoException extends ExcecaoApi {
  const ValidacaoException(super.mensagem);
}

final class NaoImplementadoException extends ExcecaoApi {
  const NaoImplementadoException([
    super.mensagem = 'Endpoint em implementação.',
  ]);
}
