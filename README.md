# Hefesto Encuestas · LimeSurvey CE
Kit de despliegue de LimeSurvey 7.5.1+261007 y MariaDB 11.4, con imagen comunitaria martialblog/limesurvey fijada por digest. Incluye Docker, secretos, respaldo/restauración, tres diseños de encuestas y guías de operación, comercialización y traspaso.

Es LimeSurvey nativo: editor de encuestas, preguntas condicionales, idiomas, participantes, respuestas, estadísticas y exportación. No es un clon. La configuración de encuestas y marca se realiza desde su administración. Las plantillas del kit son especificaciones para carga manual, no encuestas instaladas automáticamente.

## Inicio privado
Requiere Linux, Docker + Compose v2, Python 3.11+, DNS y proxy HTTPS. Dimensionamiento inicial orientativo: 2 vCPU, 4 GB RAM, espacio ajustado a adjuntos y respaldos; medir para cada cliente.
```sh
python3 scripts/configure.py cliente-demo encuestas.tudominio.cl admin@tudominio.cl
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d --build
```
Desde el computador del administrador:
```sh
ssh -L 8088:127.0.0.1:8088 usuario@servidor
```
Abrir http://localhost:8088/index.php?r=admin. Usuario admin; clave ADMIN_PASSWORD del `.env`. Completar docs/despliegue.md antes de publicar.

## Compatibilidad y estado
LimeSurvey soporta PostgreSQL además de MariaDB. Este ZIP implementa MariaDB local; no incluye conexión, certificados, roles ni pruebas contra Supabase. Su PostgreSQL podría evaluarse como backend independiente, sin incorporar automáticamente Supabase Auth/Storage. No basta cambiar DB_TYPE: el escritor de configuración de este kit está diseñado para MariaDB.

El contenedor conserva upload y application/config, incluidas las claves de cifrado security.php generadas por LimeSurvey. Nunca regenerarlas sobre datos existentes. config.php es administrado por ops/configure.php y se vuelve a escribir al arrancar; los demás archivos se conservan.

Revisión estática realizada. No desplegado ni probado con Docker/PHP en este entorno. Faltan las pruebas de aceptación en VPS. No se incluyen SMTP activo, envíos masivos, pagos, automatizaciones n8n, integración Odoo ni plugins comerciales. El ZIP contiene configuración y scripts; las imágenes se descargan al desplegar.

## Despliegue en Coolify (MVP Hefesto)

Coolify detecta `compose.yaml` y construye el stack detrás de Traefik (TLS y dominio automáticos). El compose ya no declara `name:` a nivel raíz ni `name:` en volúmenes, y todo lo que toca el host quedó fuera: el servicio `app` se expone solo en `8080` y la base no se publica.

Variables que Coolify debe inyectar (mínimo indispensable):

| Variable | Descripción | Tipo |
|----------|-------------|------|
| `SURVEY_HOST` | Dominio público (sin esquema), p. ej. `encuestas.example.com`. Se antepone `https://` al armar `HOST_INFO`. | pública |
| `ADMIN_EMAIL` | Correo del usuario `admin` sembrado. | pública |
| `ADMIN_PASSWORD` | Clave inicial del usuario `admin`. **Rotarla después del primer login** (el kit no la cambia por sí solo). | secreta |
| `DB_PASSWORD` | Clave del rol MariaDB `limesurvey`. | secreta |
| `DB_ROOT_PASSWORD` | Clave del rol `root` de MariaDB. | secreta |
| `IMAGE_TAG` | (Opcional) Tag de la imagen `hefesto-encuestas`. Por defecto `7.5.1-261007`. | pública |

`VOLUME_PREFIX` es opcional: por defecto vale `hefesto-encuestas`, que conserva los nombres de volumen del flujo tradicional (`scripts/configure.py`), de modo que las instalaciones existentes siguen encontrando sus datos tras actualizar. Si vienes desde ese flujo, basta con dejar el `.env` que ese script genera. `COMPOSE_PROJECT_NAME` lo fija Coolify y no hace falta exportarlo.

Tras el primer arranque, completar `docs/despliegue.md`. SMTP se configura dentro de LimeSurvey una vez iniciada la sesión (PHP mail está deshabilitado en `ops/php.ini`); si la app necesita correo, configurarlo antes de habilitar envíos.
