#!/usr/bin/env bash
# Verifica que compose.yaml cumpla el contrato de Coolify del kit Hefesto.
# Sale con 0 si todo cumple, con 1 si hay violaciones (imprime cada una),
# con 2 si el render de docker compose falla.
#
# No imprime secretos ni valores de variables. Solo motivos.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

env_file="$tmp/.env"
# Valores ficticios no-secretos para validar el render sin filtrar nada.
{
  echo 'COMPOSE_PROJECT_NAME=hefesto-prueba'
  echo 'VOLUME_PREFIX=hefesto-prueba'
  echo 'SURVEY_HOST=https://ejemplo.invalid'
  echo 'DB_PASSWORD=x1234567890abcdef'
  echo 'DB_ROOT_PASSWORD=xabcdef1234567890'
  echo 'ADMIN_EMAIL=admin@ejemplo.invalid'
  echo 'ADMIN_PASSWORD=xabcdef1234567890'
  echo 'IMAGE_TAG=7.5.1-261007'
} > "$env_file"

compose_file="$repo_root/compose.yaml"
if [ ! -f "$compose_file" ]; then
  echo "FATAL: no existe $compose_file" >&2
  exit 2
fi

# 1) Render del compose. Si falla, abortamos: el contrato exige que el
#    compose rinda sin error con variables ficticias (Coolify las inyecta).
set +e
render="$(docker compose --project-directory "$repo_root" \
  -f "$compose_file" --env-file "$env_file" \
  config --format json 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "FATAL: docker compose config falló (rc=$rc):" >&2
  echo "$render" >&2
  exit 2
fi

# 2) Validar el render contra los puntos 1-2 del contrato en servicios
#    sin profiles. Aquí 'declarado en YAML' == 'presente en el render'
#    para los campos de servicio: ports, container_name, privileged,
#    cap_add, devices, network_mode/pid/ipc=host, security_opt=unconfined.
read -r -d '' jq_svc <<'EOF' || true
(.services // {})
| to_entries[]
| select((.value.profiles // []) | length == 0)
| .key as $s
| (.value // {})
| (
    (if has("ports") and (.ports | length > 0) then ["\($s): tiene 'ports' declarado (contrato §1)"] else [] end),
    (if has("container_name") then ["\($s): tiene 'container_name' declarado (contrato §1)"] else [] end),
    (["privileged","cap_add","devices"] as $ks
      | [ $ks[] as $k | select(has($k)) | "\($s): tiene '\($k)' declarado (contrato §1)" ]),
    (["network_mode","pid","ipc"] as $ks
      | [ $ks[] as $k | select(.[$k] == "host") | "\($s): \($k)=host (contrato §1)" ]),
    (if (.security_opt // []) | index("unconfined") then
       ["\($s): security_opt contiene 'unconfined' (contrato §1)"] else [] end)
  )
| flatten
| .[]
EOF
svc_violations="$(printf '%s' "$render" | jq -r "$jq_svc" 2>/dev/null || true)"

# 3) Validar declaraciones explícitas en el YAML origen que el render no
#    distingue de su auto-cálculo: name raíz, volumes.X.name, networks.X.name.
yaml_violations="$(python3 - "$compose_file" <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as f:
    doc = yaml.safe_load(f) or {}
fails = []

if isinstance(doc, dict) and 'name' in doc:
    val = doc['name']
    if isinstance(val, str) and val:
        # Expandimos ${VAR} simple para que el mensaje sea legible.
        expandido = val
        for k in ('COMPOSE_PROJECT_NAME', 'VOLUME_PREFIX'):
            expandido = expandido.replace('${' + k, '«' + k)
        fails.append(f"raíz: declarado 'name: {expandido}' (contrato §2)")

def walk_volumes(d):
    if not isinstance(d, dict):
        return
    for vname, vbody in d.items():
        if isinstance(vbody, dict) and 'name' in vbody:
            expandido = str(vbody['name'])
            for k in ('VOLUME_PREFIX', 'COMPOSE_PROJECT_NAME'):
                expandido = expandido.replace('${' + k, '«' + k)
            fails.append(f"volumen {vname}: declarado 'name: {expandido}' (contrato §2)")

def walk_networks(d):
    if not isinstance(d, dict):
        return
    for nname, nbody in d.items():
        if isinstance(nbody, dict) and 'name' in nbody:
            fails.append(f"red {nname}: declarado 'name: {nbody['name']}' (contrato §2)")

walk_volumes(doc.get('volumes') or {})
walk_networks(doc.get('networks') or {})

print('\n'.join(fails) if fails else 'OK')
PY
)"

# 4) Consolida.
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
