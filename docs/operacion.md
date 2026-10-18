# Respaldos, recuperación y entrega
## Respaldar
```sh
python3 scripts/backup.py
```
Requiere Python 3.11+ y el mismo proyecto/contexto Compose que ejecuta app. Coordinar una ventana sin respuestas: detiene app y copia SQL, upload, config (incluido security.php), .env, Dockerfile y Compose; finalmente reinicia app. Solo respaldos con manifest completed son utilizables. Cifrar y copiar fuera del VPS, junto con este ZIP y cualquier cambio de ops. El manifiesto detecta corrupción, no autentica al proveedor del archivo.

Para bases importadas confirmar que las tablas usan InnoDB y que ningún proceso externo escribe durante la copia. Las respuestas en curso pueden no haberse enviado: avisar antes del mantenimiento. Programar respaldo externo luego de medir duración; no se ha instalado cron. Definir retención por contrato y verificar restauración regularmente.

## Restaurar sin sobrescribir
1. En otro proyecto/VPS, disponer del kit de la misma versión y un backup confiable. Copiar .env, Dockerfile y compose.yaml del respaldo; cambiar COMPOSE_PROJECT_NAME a un nombre nuevo. Si quieres reutilizar los mismos volúmenes del origen, deja VOLUME_PREFIX con el mismo valor (o no lo definas, porque por defecto vale `hefesto-encuestas` y conserva los nombres del flujo tradicional). Si vas a un proyecto limpio, basta con que SURVEY_HOST apunte al dominio nuevo. Mantener claves de DB; chmod 600 .env. No cambiar el origen.
2. Ejecutar `docker compose build app` y `docker compose up -d db`. Esperar DB saludable. NO arrancar app antes de restaurar: instalaría una base nueva y poblaría los volúmenes.
3. Ejecutar `python3 scripts/restore.py /ruta/backup`. Verifica hashes, exige base y volúmenes vacíos, rechaza enlaces y rutas inseguras y restaura propietarios UID 33 del contenedor. No elimina tablas ni volúmenes existentes. Si falla a mitad, usar destinos nuevos: no continuar sobre una restauración parcial.
4. Ejecutar `docker compose up -d app` y revisar logs. Verificar login, encuestas, preguntas, participantes, número de respuestas, adjuntos y descifrado de un dato de prueba. No basta comprobar que abre la página.
5. Con aceptación completa: detener entradas en origen, repetir con copia final y destino nuevo; cambiar DNS/proxy. Mantener origen detenido. Antes de retroceder después de nuevas respuestas en destino, conciliarlas para evitar pérdidas.

Conservar claves security.php: perderlas puede impedir recuperar campos cifrados. Backup también contiene participantes, respuestas y secretos. Guardar acceso en gestor de claves. No enviar respaldos sin cifrar por correo/chat.

## Actualizar
Probar primero en un clon restaurado. Registrar digest de app y MariaDB, respaldar, revisar notas de versión y diferencias de application/config. MariaDB 11.4 recibe parches de rama; fijar digest operativo si el cliente exige reproducibilidad completa. Rollback = restauración de datos y versión anterior compatible, no volver a una imagen antigua sobre un esquema migrado.

## Entrega a Hefesto/otro proveedor
Entregar código del kit, dominio/DNS, acceso Coolify, proyecto y volúmenes, versión/digests, SMTP, temas/plugins, claves y respaldo verificado. Registrar fecha, responsable y resultado de prueba. Revocar accesos salientes tras aceptación. Proxy/DNS/SMTP externos requieren exportación/documentación aparte.
