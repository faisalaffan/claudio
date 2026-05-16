FROM dart:stable

LABEL org.opencontainers.image.source="https://github.com/faisalaffan/claudio"
LABEL org.opencontainers.image.description="Multi-provider AI SDK for Dart"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .

RUN dart analyze lib/
