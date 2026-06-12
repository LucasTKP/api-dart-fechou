# --- Estágio de build ---
FROM dart:stable AS build

WORKDIR /app

# Instala o Dart Frog CLI (necessário para gerar o build de produção)
RUN dart pub global activate dart_frog_cli

# Resolve dependências primeiro (melhora o cache de camadas)
COPY pubspec.* ./
RUN dart pub get

# Copia o restante do código e gera o build do Dart Frog
COPY . .
RUN dart pub get --offline
RUN dart pub global run dart_frog_cli:dart_frog build

# Compila o servidor gerado para um executável nativo
WORKDIR /app/build
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

# --- Imagem final mínima ---
FROM scratch

# Runtime do Dart necessário para o executável AOT
COPY --from=build /runtime/ /
COPY --from=build /app/build/bin/server /app/bin/server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/bin/server"]
