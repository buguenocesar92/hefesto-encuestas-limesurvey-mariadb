# Contrato de variables — hefesto-encuestas (LimeSurvey + MariaDB)

Estado: vigente desde 2026-10-20. Este documento convierte los comentarios de
`.env.example` en una tabla navegable y deja claro que variable es
obligatoria, que ocurre si falta y como se genera su valor.

## 1. Tabla de variables

| Variable | Obligatoria | Generacion | Efecto |
|---|---|---|---|
| `VOLUME_PREFIX` | no | valor por defecto | Prefijo de los volumenes `db`, `upload` y `config`. Cambiarlo en un kit ya desplegado deja los volumenes anteriores huerfanos. |
| `SURVEY_HOST` | **si** | dominio del cliente | Host publico de la encuesta. `compose.yaml` aborta si falta. |
| `ADMIN_EMAIL` | **si** (bootstrap) | correo del cliente | Cuenta del administrador inicial. La usa solo `compose.bootstrap.yaml`. |
| `ADMIN_PASSWORD` | **si** (bootstrap) | `openssl rand -base64 32` | Clave del administrador inicial. Se aplica **una vez**: despues se borra del entorno y el compose de produccion no la necesita. |
| `DB_PASSWORD` | **si** | `openssl rand -base64 32` | Clave del usuario de aplicacion `limesurvey` sobre MariaDB. |
| `DB_ROOT_PASSWORD` | **si** | `openssl rand -base64 32` | Clave del usuario root de MariaDB. |
| `IMAGE_TAG` | no | etiqueta fijada | Debe coincidir con la version fijada en `Dockerfile` (`7.5.1-261007`). |

## 2. Reglas de operacion

1. **El `.env` real nunca se versiona.** Se copia `.env.example`, se sustituyen
   los marcadores `GENERAR_CON_OPENSSL_RAND_BASE64_32` y el fichero queda con
   permisos `0600`.
2. **Ningun placeholder del compose puede faltar.** `tests/env-example.bats`
   comprueba que todo `${VARIABLE}` de `compose.yaml` y `compose.bootstrap.yaml`
   aparece en `.env.example`.
3. **Sin valores reales en la plantilla.** La plantilla solo admite marcadores
   `GENERAR`; un valor real es un secreto filtrado.
4. **La clave del administrador inicial es efimera.** Tras el alta, se borra
   `ADMIN_PASSWORD` del entorno: `compose.bootstrap.yaml` no debe quedar
   aplicado en el despliegue permanente.
5. **El respaldo nunca lleva el `.env` en claro.** Solo los nombres de las
   variables (`env.vars`) y, si hay receptor `age`, el `.env` cifrado
   (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`.
6. **Los volumenes con material personal viajan cifrados.** `upload` (respuestas
   y adjuntos) y `config` (clave de cifrado de la aplicacion) solo se respaldan
   cifrados con `age` o no se respaldan y el manifiesto lo declara.

## 3. Verificacion

```bash
bats tests/                      # suite completa del kit
bats tests/env-example.bats      # contrato de variables
docker compose --env-file .env.example -f compose.yaml config --quiet
docker compose --env-file .env.example -f compose.yaml -f compose.bootstrap.yaml config --quiet
```

## 4. Datos personales

Las respuestas de las encuestas y los datos de los participantes son datos
personales: inventario, base legal, retencion y derechos del titular estan en
`docs/POLITICA-DATOS-PERSONALES.md` (Ley 21.719).
