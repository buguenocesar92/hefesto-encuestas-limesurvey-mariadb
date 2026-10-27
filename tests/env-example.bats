#!/usr/bin/env bats
# Contrato de variables del kit hefesto-encuestas (LimeSurvey + MariaDB).
#
# Verifica que .env.example cubra todos los placeholders del compose y que no
# asigne secretos reales.

load 'ayudante'

@test "todo placeholder del compose aparece en .env.example" {
  for v in $(grep -hoE '\$\{[A-Z_]+' compose.yaml compose.bootstrap.yaml | sed 's/\${//' | sort -u); do
    run grep -qE "^${v}=" .env.example
    [ "$status" -eq 0 ] || { echo "Falta $v en .env.example"; return 1; }
  done
}

@test ".env.example no asigna secretos reales" {
  run grep -nE '^(DB_PASSWORD|DB_ROOT_PASSWORD|ADMIN_PASSWORD)=.+' .env.example
  # Solo se admite el marcador GENERAR, nunca un valor real.
  if [ -n "$output" ]; then
    [[ "$output" == *"GENERAR"* ]] || { echo "Hay un valor real en .env.example"; return 1; }
  fi
}

@test "el compose renderiza con el .env de ejemplo" {
  run docker compose --env-file .env.example -f compose.yaml config --quiet
  [ "$status" -eq 0 ]
}

@test "el compose bootstrap renderiza con el .env de ejemplo" {
  run docker compose --env-file .env.example -f compose.yaml -f compose.bootstrap.yaml config --quiet
  [ "$status" -eq 0 ]
}
