#!/usr/bin/env bash
# Verifica que compose.yaml cumpla el contrato de Coolify del kit Hefesto.
# Sale con 0 si todo cumple, con 1 si hay violaciones (imprime cada una),
# con 2 si el render de docker compose falla o falta una dependencia.
#
# No imprime secretos ni valores de variables. Solo motivos.
set -euo pipefail

# Dependencias obligatorias: si falta alguna, abortamos en vez de fallar
# silenciosamente (revisión punto 6).
for bin in jq docker python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "FATAL: dependencia faltante: $bin" >&2
    exit 2
  fi
done

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

compose_file="$repo_root/compose.yaml"
if [ ! -f "$compose_file" ]; then
  echo "FATAL: no existe $compose_file" >&2
  exit 2
fi

# 1) Generar el .env temporal extrayendo las ${VAR} del compose (revisión
#    punto 7): un valor ficticio no-secreto por cada variable referenciada.
#    Las que parecen host/URL van con https://ejemplo.invalid; el resto,
#    con un placeholder opaco.
env_file="$tmp/.env"
{
  mapfile -t vars < <(grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*' "$compose_file" \
    | sed -E 's/^\$\{//' | sort -u)
  for v in "${vars[@]}"; do
    if [[ "$v" == *HOST* || "$v" == *URL* ]]; then
      val="https://ejemplo.invalid"
    else
      val="x1234567890abcdef"
    fi
    printf '%s=%s\n' "$v" "$val"
  done
} > "$env_file"

# 2) Render del compose. Si falla, abortamos: el contrato exige que el
#    compose rinda sin error con variables ficticias (Coolify las inyecta).
#    Capturamos stdout (JSON) y stderr (warnings/errores) por separado;
#    si los warnings se mezclan al JSON, jq falla con parse error y el
#    chequeo se vuelve silencioso.
set +e
stderr_file="$tmp/stderr"
render="$(docker compose --project-directory "$repo_root" \
  -f "$compose_file" --env-file "$env_file" \
  config --format json 2>"$stderr_file")"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "FATAL: docker compose config falló (rc=$rc):" >&2
  cat "$stderr_file" >&2
  exit 2
fi

# 3) Validar el render contra los puntos 1-2 del contrato en servicios
#    sin profiles: ports, container_name, privileged, cap_add, devices,
#    network_mode/pid/ipc=host, security_opt con 'unconfined' (cualquier
#    forma: seccomp:unconfined, apparmor:unconfined, etc.; revisión punto 5)
#    y bind mounts fuera del repo o apuntando a docker.sock (revisión
#    punto 4). El filtro vive en un archivo (read -d '' con set -e aborta
#    en el EOF) y se pasa por --from-file; sin 2>/dev/null || true, si
#    jq falla queremos ver el error (revisión punto 6).
jq_svc_file="$tmp/jq-svc.jq"
cat > "$jq_svc_file" <<'JQEOS'
(.services // {})
| to_entries[]
| select((.value.profiles // []) | length == 0)
| .key as $svc
| (.value // {})
| (
    (if has("ports") and (.ports | length > 0) then ["\($svc): tiene 'ports' declarado (contrato §1)"] else [] end),
    (if has("container_name") then ["\($svc): tiene 'container_name' declarado (contrato §1)"] else [] end),
    (["privileged","cap_add","devices"] as $ks
      | [ $ks[] as $k | select(has($k)) | "\($svc): tiene '\($k)' declarado (contrato §1)" ]),
    (["network_mode","pid","ipc"] as $ks
      | [ $ks[] as $k | select(.[$k] == "host") | "\($svc): \($k)=host (contrato §1)" ]),
    (if (.security_opt // []) | any(. | tostring | test("unconfined")) then
       ["\($svc): security_opt contiene 'unconfined' (contrato §1)"] else [] end),
    ([ ((.volumes // [])[]
        | select(.type == "bind")
        | (if (.source // "") == "/var/run/docker.sock" then
             "\($svc): bind a docker.sock (contrato §1)"
           elif ((.source // "") | startswith($repo_root) | not) then
             "\($svc): bind fuera del repo (\(.source // ""))"
           else empty end)
      ) ] | flatten)
  )
| flatten
| .[]
JQEOS
svc_violations="$(printf '%s' "$render" | jq -r --arg repo_root "$repo_root" --from-file "$jq_svc_file")"

# 4) Validar declaraciones explícitas en el YAML origen que el render no
#    distingue de su auto-cálculo: name raíz, volumes.X.name, networks.X.name.
#    Para volumes.X.name aceptamos ${VOLUME_PREFIX:-…} (con valor por
#    defecto), y seguimos fallando con nombre literal fijo o con
#    ${VOLUME_PREFIX} / ${VOLUME_PREFIX:?…} sin default (revisión punto 2).
yaml_violations="$(python3 - "$compose_file" <<'PY'
import sys, yaml, re
path = sys.argv[1]
with open(path) as f:
    doc = yaml.safe_load(f) or {}
fails = []

def expand(val):
    out = str(val)
    for k in ('COMPOSE_PROJECT_NAME', 'VOLUME_PREFIX'):
        out = out.replace('${' + k, '«' + k)
    return out

if isinstance(doc, dict) and 'name' in doc:
    val = doc['name']
    if isinstance(val, str) and val:
        fails.append(f"raíz: declarado 'name: {expand(val)}' (contrato §2)")

def walk_volumes(d):
    if not isinstance(d, dict):
        return
    for vname, vbody in d.items():
        if isinstance(vbody, dict) and 'name' in vbody:
            nombre = str(vbody['name'])
            # Aceptar ${VOLUME_PREFIX:-algo} (default), fallar en literal fijo
            # y en ${VAR} / ${VAR:?…} sin default.
            if not re.search(r'\$\{[A-Za-z_][A-Za-z0-9_]*:-[^}]*\}', nombre):
                fails.append(
                    f"volumen {vname}: declarado 'name: {expand(nombre)}' "
                    f"(contrato §2)"
                )

def walk_networks(d):
    if not isinstance(d, dict):
        return
    for nname, nbody in d.items():
        if isinstance(nbody, dict) and 'name' in nbody:
            fails.append(f"red {nname}: declarado 'name: {expand(nbody['name'])}' (contrato §2)")

walk_volumes(doc.get('volumes') or {})
walk_networks(doc.get('networks') or {})

print('\n'.join(fails) if fails else 'OK')
PY
)"

# 5) Consolida.
fails=0
emit() {
  while IFS= read -r linea; do
    [ -n "$linea" ] || continue
    echo "FAIL: $linea"
    fails=$((fails + 1))
  done <<< "$1"
}

if [ -n "$svc_violations" ]; then emit "$svc_violations"; fi
if [ -n "$yaml_violations" ] && [ "$yaml_violations" != "OK" ]; then
  emit "$yaml_violations"
fi

if [ "$fails" -gt 0 ]; then
  echo "coolify-check: FAIL ($fails violación/es)" >&2
  exit 1
fi
echo "coolify-check: OK"
exit 0