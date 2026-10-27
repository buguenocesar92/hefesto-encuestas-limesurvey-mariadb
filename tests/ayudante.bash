# ayudante: kit de pruebas aislado para hefesto-encuestas.
#
# Nunca toca el .env real ni Docker real: el kit se copia a un directorio
# temporal con un .env sintetico y los stubs de tests/stubs/ responden por
# Docker.
RAIZ="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export RAIZ
export HEFESTO_KIT_TEST=1
export PATH="$RAIZ/tests/stubs:$PATH"

preparar_kit() {
  KIT="$BATS_TEST_TMPDIR/kit"
  rm -rf "$KIT"
  mkdir -p "$KIT"
  cp -R "$RAIZ/scripts" "$KIT/scripts"
  rm -rf "$KIT/scripts/__pycache__"
  for extra in compose.yaml compose.bootstrap.yaml compose.rehearsal.yaml Dockerfile; do
    if [ -f "$RAIZ/$extra" ]; then cp "$RAIZ/$extra" "$KIT/$extra"; fi
  done
  for dir in ops certs; do
    if [ -d "$RAIZ/$dir" ]; then cp -R "$RAIZ/$dir" "$KIT/$dir"; fi
  done
  mkdir -p "$KIT/backups"
  cat > "$KIT/.env" <<'ENV'
VOLUME_PREFIX='hefesto-encuestas-test'
DB_PASSWORD='valor-ficticio-no-real'
DB_ROOT_PASSWORD='valor-ficticio-no-real'
ADMIN_EMAIL='admin@example.invalid'
ADMIN_PASSWORD='valor-ficticio-no-real'
SURVEY_HOST='encuestas.example.invalid'
IMAGE_TAG='7.5.1-261007'

ENV
  chmod 600 "$KIT/.env"
  export KIT
}

preparar_datos() {
  export STUB_DUMP_FILE="$BATS_TEST_TMPDIR/dump.sql"
  printf -- '-- dump sintetico\nCREATE TABLE demo(id int);\n' > "$STUB_DUMP_FILE"
  export STUB_TAR_DIR="$BATS_TEST_TMPDIR/tar"
  mkdir -p "$STUB_TAR_DIR/data"
  printf 'archivo sintetico\n' > "$STUB_TAR_DIR/data/demo.txt"
  export STUB_RUNNING=1
  export STUB_FIND_OUTPUT=""
  export STUB_PSQL_OUT=0
  export STUB_STATE_FILE="$BATS_TEST_TMPDIR/servicios-detenidos"
  : > "$STUB_STATE_FILE"
}

generar_receptor_age() {
  # Genera un par de claves age efimero SOLO en el directorio temporal de la
  # prueba. Nunca se versiona ni se usa fuera de la suite.
  if ! command -v age-keygen >/dev/null 2>&1; then
    return 1
  fi
  local dir="$BATS_TEST_TMPDIR/age"
  mkdir -p "$dir"
  chmod 700 "$dir"
  if ! age-keygen -o "$dir/clave.txt" >/dev/null 2>&1; then
    return 1
  fi
  AGE_RECIPIENT="$(sed -n 's/^# public key: //p' "$dir/clave.txt")"
  export AGE_RECIPIENT
  export AGE_IDENTITY_FILE="$dir/clave.txt"
  [ -n "$AGE_RECIPIENT" ]
}
