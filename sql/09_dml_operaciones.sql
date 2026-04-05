INSERT INTO oltp_operaciones.servicio
(id_servicio, nombre_servicio, categoria_servicio, precio_base, activo)
VALUES
(1, 'Desayuno buffet', 'restauracion', 18.00, TRUE),
(2, 'Cena temática', 'restauracion', 34.00, TRUE),
(3, 'Circuito spa', 'spa', 30.00, TRUE),
(4, 'Masaje relajante', 'spa', 62.00, TRUE),
(5, 'Traslado aeropuerto', 'transporte', 45.00, TRUE),
(6, 'Excursión urbana', 'ocio', 38.00, TRUE),
(7, 'Alquiler de bicicleta', 'ocio', 17.00, TRUE),
(8, 'Sala de reuniones', 'evento', 140.00, TRUE),
(9, 'Coffee break', 'evento', 9.00, TRUE),
(10, 'Cena privada', 'evento', 95.00, TRUE),
(11, 'Minibar premium', 'restauracion', 12.00, TRUE),
(12, 'Tratamiento facial', 'spa', 48.00, TRUE),
(13, 'Cata gastronómica', 'ocio', 52.00, TRUE),
(14, 'Shuttle corporativo', 'transporte', 25.00, TRUE),
(15, 'Fiesta temática nocturna', 'evento', 70.00, FALSE);

INSERT INTO oltp_operaciones.proveedor_servicio
(id_proveedor_servicio, nombre_proveedor, nif, tipo_servicio, telefono, email, ciudad)
VALUES
(1, 'Mantenimiento Costa Sur', 'B12345678', 'mantenimiento general', '+34-952111111', 'contacto@costasur.es', 'Málaga'),
(2, 'ClimaTech Sevilla', 'B22345678', 'climatizacion', '+34-954222222', 'info@climatech.es', 'Sevilla'),
(3, 'Fontanería Levante', 'B32345678', 'fontaneria', '+34-963333333', 'hola@levantefont.es', 'Valencia'),
(4, 'Electricidad Palma', 'B42345678', 'electricidad', '+34-971444444', 'soporte@electricpalma.es', 'Palma'),
(5, 'Jardines Atlántico', 'B52345678', 'jardineria', '+34-922555555', 'admin@jatlantico.es', 'Adeje'),
(6, 'Eventos Premium', 'B62345678', 'eventos', '+34-915666666', 'eventos@premium.es', 'Madrid'),
(7, 'Lavandería Blanca', 'B72345678', 'limpieza', '+34-933777777', 'clientes@blanca.es', 'Barcelona'),
(8, 'Seguridad Integral', 'B82345678', 'seguridad', '+34-913888888', 'contacto@segintegral.es', 'Madrid'),
(9, 'Wellness Balance', 'B92345678', 'spa', '+34-958999999', 'spa@balance.es', 'Granada'),
(10, 'Movilidad Mediterránea', 'B13345678', 'transporte', '+34-964123123', 'movilidad@mediterranea.es', 'Valencia'),
(11, 'AudioVisual Norte', 'B23345678', 'eventos', '+34-943555111', 'pro@avnorte.es', 'San Sebastián'),
(12, 'Limpieza Verde', 'B33345678', 'limpieza', '+34-952444333', 'info@limpiezaverde.es', 'Marbella');

INSERT INTO oltp_operaciones.incidencia
(id_incidencia, id_hotel, id_habitacion, tipo_incidencia, descripcion, fecha_apertura, fecha_cierre, prioridad, estado_incidencia)
SELECT
    gs AS id_incidencia,
    ((gs - 1) % 8) + 1 AS id_hotel,
    ((((gs - 1) % 8) * 16) + (((gs * 3) % 16) + 1)) AS id_habitacion,
    CASE ((gs - 1) % 6)
        WHEN 0 THEN 'mantenimiento'
        WHEN 1 THEN 'limpieza'
        WHEN 2 THEN 'electricidad'
        WHEN 3 THEN 'fontaneria'
        WHEN 4 THEN 'climatizacion'
        ELSE 'otro'
    END AS tipo_incidencia,
    'Incidencia operativa registrada automáticamente ' || gs AS descripcion,
    DATE '2023-01-10' + ((gs * 5) % 1050) AS fecha_apertura,
    CASE
        WHEN gs % 9 = 0 OR gs % 7 = 0 THEN NULL
        ELSE DATE '2023-01-10' + ((gs * 5) % 1050) + ((gs % 10) + 1)
    END AS fecha_cierre,
    CASE
        WHEN gs % 15 = 0 THEN 'critica'
        WHEN gs % 5 = 0 THEN 'alta'
        WHEN gs % 3 = 0 THEN 'media'
        ELSE 'baja'
    END AS prioridad,
    CASE
        WHEN gs % 9 = 0 THEN 'abierta'
        WHEN gs % 7 = 0 THEN 'en_proceso'
        WHEN gs % 2 = 0 THEN 'cerrada'
        ELSE 'resuelta'
    END AS estado_incidencia
FROM generate_series(1, 220) AS gs;

INSERT INTO oltp_operaciones.mantenimiento
(id_mantenimiento, id_incidencia, id_proveedor_servicio, fecha_mantenimiento, coste_mantenimiento, resultado, estado_mantenimiento)
SELECT
    ROW_NUMBER() OVER (ORDER BY i.id_incidencia) AS id_mantenimiento,
    i.id_incidencia,
    CASE i.tipo_incidencia
        WHEN 'mantenimiento' THEN 1
        WHEN 'limpieza' THEN 7
        WHEN 'electricidad' THEN 4
        WHEN 'fontaneria' THEN 3
        WHEN 'climatizacion' THEN 2
        ELSE 6
    END AS id_proveedor_servicio,
    i.fecha_apertura + ((i.id_incidencia % 8) + 1) AS fecha_mantenimiento,
    ROUND((80 + (i.id_incidencia % 9) * 27.5 + CASE i.prioridad
        WHEN 'critica' THEN 150
        WHEN 'alta' THEN 80
        WHEN 'media' THEN 35
        ELSE 0
    END)::NUMERIC, 2) AS coste_mantenimiento,
    CASE
        WHEN i.estado_incidencia IN ('resuelta', 'cerrada') THEN 'Incidencia solucionada'
        ELSE 'Actuación programada'
    END AS resultado,
    CASE
        WHEN i.estado_incidencia IN ('resuelta', 'cerrada') THEN 'realizado'
        ELSE 'programado'
    END AS estado_mantenimiento
FROM oltp_operaciones.incidencia i
WHERE i.estado_incidencia IN ('resuelta', 'cerrada', 'en_proceso');

WITH base_consumo AS (
    SELECT
        r.id_reserva,
        r.id_cliente,
        d.id_hotel,
        d.fecha_entrada,
        d.noches_reservadas,
        c.tipo_cliente
    FROM oltp_reservas.reserva r
    JOIN oltp_reservas.detalle_reserva d
      ON d.id_reserva = r.id_reserva
    JOIN oltp_reservas.cliente c
      ON c.id_cliente = r.id_cliente
    WHERE r.estado_reserva IN ('confirmada', 'completada')
), eventos AS (
    SELECT
        bc.*,
        gs.n,
        CASE
            WHEN bc.tipo_cliente = 'premium' THEN (ARRAY[3,4,10,11,12,13])[((bc.id_reserva + gs.n - 2) % 6) + 1]
            WHEN bc.tipo_cliente = 'corporativo' THEN (ARRAY[5,8,9,14])[((bc.id_reserva + gs.n - 2) % 4) + 1]
            ELSE (ARRAY[1,2,6,7,11])[((bc.id_reserva + gs.n - 2) % 5) + 1]
        END AS id_servicio
    FROM base_consumo bc
    CROSS JOIN LATERAL generate_series(
        1,
        CASE
            WHEN bc.tipo_cliente = 'premium' THEN 3
            WHEN bc.tipo_cliente = 'corporativo' THEN 2
            ELSE ((bc.id_reserva % 2) + 1)
        END
    ) AS gs(n)
), eventos_cantidad AS (
    SELECT
        e.*,
        CASE
            WHEN e.id_servicio IN (1, 2, 9, 11) THEN 2
            WHEN e.id_servicio = 7 THEN 1 + (e.id_reserva % 3)
            ELSE 1 + ((e.id_reserva + e.n) % 2)
        END AS cantidad
    FROM eventos e
)
INSERT INTO oltp_operaciones.consumo_servicio
(id_consumo_servicio, id_servicio, id_reserva, id_hotel, fecha_consumo, cantidad, importe_total, observaciones)
SELECT
    ROW_NUMBER() OVER (ORDER BY ec.id_reserva, ec.n) AS id_consumo_servicio,
    ec.id_servicio,
    ec.id_reserva,
    ec.id_hotel,
    ec.fecha_entrada + ((ec.id_reserva + ec.n - 1) % GREATEST(ec.noches_reservadas, 1)) AS fecha_consumo,
    ec.cantidad,
    ROUND((ec.cantidad * s.precio_base * CASE
        WHEN ec.tipo_cliente = 'premium' AND ec.id_servicio IN (3,4,12,13) THEN 0.95
        WHEN ec.tipo_cliente = 'corporativo' AND ec.id_servicio IN (8,9,14) THEN 0.90
        ELSE 1.00
    END)::NUMERIC, 2) AS importe_total,
    CASE
        WHEN ec.tipo_cliente = 'corporativo' THEN 'Cargo asociado a estancia corporativa'
        WHEN ec.tipo_cliente = 'premium' THEN 'Servicio premium cargado a habitación'
        ELSE 'Consumo habitual durante la estancia'
    END AS observaciones
FROM eventos_cantidad ec
JOIN oltp_operaciones.servicio s
  ON s.id_servicio = ec.id_servicio;

SELECT setval('oltp_operaciones.servicio_id_servicio_seq', (SELECT MAX(id_servicio) FROM oltp_operaciones.servicio), true);
SELECT setval('oltp_operaciones.proveedor_servicio_id_proveedor_servicio_seq', (SELECT MAX(id_proveedor_servicio) FROM oltp_operaciones.proveedor_servicio), true);
SELECT setval('oltp_operaciones.incidencia_id_incidencia_seq', (SELECT MAX(id_incidencia) FROM oltp_operaciones.incidencia), true);
SELECT setval('oltp_operaciones.mantenimiento_id_mantenimiento_seq', (SELECT MAX(id_mantenimiento) FROM oltp_operaciones.mantenimiento), true);
SELECT setval('oltp_operaciones.consumo_servicio_id_consumo_servicio_seq', (SELECT MAX(id_consumo_servicio) FROM oltp_operaciones.consumo_servicio), true);
