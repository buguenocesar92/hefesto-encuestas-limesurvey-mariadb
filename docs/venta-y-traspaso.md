# Oferta comercial y traspaso
Servicio propuesto: instalación por empresa + diseño de encuestas + capacitación + soporte y respaldos mensuales. Nichos: agencias, prestadores de servicios, centros de capacitación y consultoras. Cobrar implementación y operación según encuestas, usuarios, adjuntos y volumen; no hay tarifas de mercado verificadas ni ingresos garantizados en este kit.

Piloto de venta: una encuesta de satisfacción, enlace/QR, una semana de respuestas autorizadas y reporte agregado. Definir qué incluye la mensualidad, plazo de atención, espacio, retención y exportación de salida. No hay pasarela de pagos ni suscripciones automatizadas implementadas.

## Exportación y Odoo
Para migrar otra instancia LimeSurvey usar respaldo completo probado; para reutilizar encuesta usar exportaciones nativas LSS/LSA según alcance. LSS representa estructura; no asumir que contiene respuestas, participantes, adjuntos y configuración global. Guardar además exportaciones nativas de respuestas/participantes y verificar su contenido.

Odoo no es destino compatible con la base SQL LimeSurvey. Si se decide usar su módulo Encuestas, reconstruir preguntas, reglas y permisos y ensayar importación de respuestas según versión/edición. No existe un conector automático en este ZIP.

| Origen | Destino propuesto | Control |
|---|---|---|
| Encuesta y pregunta | Encuesta/pregunta de Odoo | Tipos, reglas, idiomas |
| Código de respuesta | ID externo o archivo histórico | Unicidad y fecha de corte |
| Participante autorizado | Contacto | Duplicados, permiso, propósito |
| Respuesta anónima | Datos agregados/archivo | No intentar identificar autor |
| Adjunto | Archivo autorizado | Accesos, tipos y retención |

Exportar originales, crear tabla de correspondencias y hacer prueba con un subconjunto. Conciliar cantidad de preguntas, participantes, respuestas completas/incompletas y valores. Documentar campos/reglas sin equivalente antes de aprobar corte. Mantener archivo histórico si el destino no representa todo.

## Operación de datos
Acordar finalidad, campos mínimos, responsables, retención, exportación y borrado. Probar configuración de anonimato, roles y logs en cada proyecto. El paquete no certifica cumplimiento legal ni convierte automáticamente encuestas identificadas en anónimas. No activar almacenamiento de datos sensibles por defecto.
