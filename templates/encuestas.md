# Tres diseños para crear desde LimeSurvey
Son guiones, no archivos LSS importables. Crear cada encuesta en borrador, revisar tipos/opciones y probar antes de activarla.

## Satisfacción después de un servicio
Título: ¿Cómo fue tu experiencia? Tiempo estimado: 2 minutos.
- SAT: satisfacción general, escala 1–5 (muy insatisfecho → muy satisfecho), obligatoria.
- NPS: probabilidad de recomendar, 0–10, obligatoria.
- MOTIVO: texto opcional «¿Qué influyó más en tu evaluación?».
- MEJORA: texto «¿Qué podemos mejorar?», mostrar cuando SAT ≤ 3.
No pedir nombre, correo ni número de pedido si el objetivo es anónimo. Configurar anonimización y desactivar IP/referrer/fechas detalladas cuando corresponda; revisar también proxy y logs. Anonimizar en la encuesta no anonimiza todos los registros del servidor.

## Evaluación de una capacitación
- CLARIDAD: escala 1–5.
- UTILIDAD: escala 1–5.
- RITMO: lento/adecuado/rápido.
- APLICACION: texto «¿Qué aplicarás en tu trabajo?».
- TEMAS: selección múltiple de contenidos futuros, definidos por el cliente.
Una encuesta por curso o código de curso no identificador personal. Reportar resultados agregados y número de respuestas.

## Diagnóstico de necesidades empresariales
- RUBRO: selección única.
- EQUIPO: 1, 2–5, 6–20, más de 20.
- PROCESOS: selección múltiple ventas/inventario/agenda/documentos/atención/otros.
- PRIORIDAD: selección única entre procesos anteriores.
- PLAZO: este mes/1–3 meses/explorando.
- CONTACTO: correo opcional, solo si solicita contacto.
- AUTORIZA: sí/no «Quiero que me contacten sobre esta solicitud»; mostrar correo cuando sí.
Esta encuesta no es anónima si recoge contacto. No reutilizar respuestas para campañas sin autorización correspondiente.

## Reporte de resultados
NPS = 100 × (promotores 9–10 − detractores 0–6) / respuestas válidas. Pasivos 7–8 cuentan en denominador. CSAT = 100 × respuestas 4–5 / respuestas válidas 1–5. Reportar muestra y período; no representar una muestra voluntaria como estadísticamente representativa sin diseño apropiado.
