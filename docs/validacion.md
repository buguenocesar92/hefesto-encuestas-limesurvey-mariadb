# Revisión del paquete

Completado: sintaxis YAML y Python; sintaxis shell del arranque; aislamiento de puertos de producción; bootstrap localhost; rutas persistentes de upload/config; imagen base fijada; generador de .env probado en directorio temporal con permisos 0600 y rechazo de sobrescritura; ZIP comprobado sin secretos reales.

Pendiente: lint PHP, docker compose config/build, arranque, instalación/migraciones, login, permisos, encuesta completa, SMTP, HTTPS/Coolify, backup/restauración reales y rendimiento. No se dispone de PHP/Docker ejecutables para validar esos flujos aquí. Los scripts de respaldo/restauración están revisados estáticamente, no ensayados contra un servidor.
