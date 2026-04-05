INSERT INTO oltp_finanzas.centro_coste
(id_centro_coste, id_hotel, codigo_centro, nombre_centro, categoria_centro)
SELECT
    ROW_NUMBER() OVER (ORDER BY h.id_hotel, c.orden) AS id_centro_coste,
    h.id_hotel,
    'CC-' || LPAD(h.id_hotel::TEXT, 2, '0') || '-' || c.codigo AS codigo_centro,
    c.nombre || ' ' || h.nombre_hotel AS nombre_centro,
    c.categoria AS categoria_centro
FROM oltp_alojamientos.hotel h
CROSS JOIN (VALUES
    (1, 'ALO', 'Alojamiento', 'alojamiento'),
    (2, 'RES', 'Restauración', 'restauracion'),
    (3, 'MTO', 'Mantenimiento', 'mantenimiento'),
    (4, 'COM', 'Comercial', 'comercial')
) AS c(orden, codigo, nombre, categoria);

WITH facturas_reserva AS (
    SELECT
        (4 * (d.id_hotel - 1)) + 1 AS id_centro_coste,
        r.id_reserva,
        'FAC-R-' || LPAD(r.id_reserva::TEXT, 6, '0') AS numero_factura,
        d.fecha_salida AS fecha_factura,
        ROUND((d.importe_previsto * CASE
            WHEN r.id_reserva % 5 = 0 THEN 1.18
            WHEN r.id_reserva % 3 = 0 THEN 1.10
            ELSE 1.05
        END)::NUMERIC, 2) AS importe_total,
        CASE
            WHEN r.estado_reserva = 'completada' THEN 'pagada'
            WHEN r.estado_reserva = 'confirmada' AND r.id_reserva % 4 = 0 THEN 'pendiente'
            ELSE 'emitida'
        END AS estado_factura
    FROM oltp_reservas.reserva r
    JOIN oltp_reservas.detalle_reserva d
      ON d.id_reserva = r.id_reserva
    WHERE r.estado_reserva IN ('confirmada', 'completada')
), facturas_internas AS (
    SELECT
        ((gs - 1) % 32) + 1 AS id_centro_coste,
        NULL::INT AS id_reserva,
        'FAC-I-' || LPAD(gs::TEXT, 6, '0') AS numero_factura,
        DATE '2023-01-15' + ((gs * 11) % 1050) AS fecha_factura,
        ROUND((180 + (gs % 11) * 42.5)::NUMERIC, 2) AS importe_total,
        CASE
            WHEN gs % 9 = 0 THEN 'pendiente'
            WHEN gs % 13 = 0 THEN 'anulada'
            ELSE 'pagada'
        END AS estado_factura
    FROM generate_series(1, 80) AS gs
), todas AS (
    SELECT * FROM facturas_reserva
    UNION ALL
    SELECT * FROM facturas_internas
)
INSERT INTO oltp_finanzas.factura
(id_factura, id_centro_coste, id_reserva, numero_factura, fecha_factura, importe_total, estado_factura)
SELECT
    ROW_NUMBER() OVER (ORDER BY fecha_factura, numero_factura) AS id_factura,
    id_centro_coste,
    id_reserva,
    numero_factura,
    fecha_factura,
    importe_total,
    estado_factura
FROM todas;

WITH factura_base AS (
    SELECT
        f.id_factura,
        f.id_reserva,
        f.importe_total,
        cc.categoria_centro
    FROM oltp_finanzas.factura f
    JOIN oltp_finanzas.centro_coste cc
      ON cc.id_centro_coste = f.id_centro_coste
), lineas AS (
    SELECT
        fb.id_factura,
        1 AS orden,
        CASE
            WHEN fb.id_reserva IS NOT NULL THEN 'Alojamiento'
            WHEN fb.categoria_centro = 'comercial' THEN 'Campaña digital'
            WHEN fb.categoria_centro = 'mantenimiento' THEN 'Repuesto o intervención técnica'
            WHEN fb.categoria_centro = 'restauracion' THEN 'Aprovisionamiento de restaurante'
            ELSE 'Gasto operativo general'
        END AS concepto,
        1 AS cantidad,
        CASE
            WHEN fb.id_reserva IS NOT NULL THEN ROUND((fb.importe_total * 0.85)::NUMERIC, 2)
            ELSE fb.importe_total
        END AS subtotal
    FROM factura_base fb

    UNION ALL

    SELECT
        fb.id_factura,
        2 AS orden,
        'Servicios complementarios' AS concepto,
        1 AS cantidad,
        ROUND((fb.importe_total * 0.15)::NUMERIC, 2) AS subtotal
    FROM factura_base fb
    WHERE fb.id_reserva IS NOT NULL
)
INSERT INTO oltp_finanzas.linea_factura
(id_linea_factura, id_factura, concepto, cantidad, precio_unitario, subtotal)
SELECT
    ROW_NUMBER() OVER (ORDER BY id_factura, orden) AS id_linea_factura,
    id_factura,
    concepto,
    cantidad,
    subtotal AS precio_unitario,
    subtotal
FROM lineas;

WITH costes_mantenimiento AS (
    SELECT
        ((i.id_hotel - 1) * 4) + 3 AS id_centro_coste,
        m.id_mantenimiento,
        m.fecha_mantenimiento AS fecha_coste,
        'mantenimiento' AS tipo_coste,
        m.coste_mantenimiento AS importe,
        'Coste vinculado a mantenimiento de incidencia ' || m.id_incidencia AS descripcion
    FROM oltp_operaciones.mantenimiento m
    JOIN oltp_operaciones.incidencia i
      ON i.id_incidencia = m.id_incidencia
), costes_genericos AS (
    SELECT
        ((gs - 1) % 32) + 1 AS id_centro_coste,
        NULL::INT AS id_mantenimiento,
        DATE '2023-01-20' + ((gs * 13) % 1050) AS fecha_coste,
        CASE
            WHEN gs % 7 = 0 THEN 'marketing'
            WHEN gs % 5 = 0 THEN 'limpieza'
            WHEN gs % 3 = 0 THEN 'personal'
            WHEN gs % 11 = 0 THEN 'mantenimiento'
            ELSE 'suministro'
        END AS tipo_coste,
        ROUND((95 + (gs % 14) * 26.75)::NUMERIC, 2) AS importe,
        'Coste operativo periódico ' || gs AS descripcion
    FROM generate_series(1, 260) AS gs
), todos_costes AS (
    SELECT * FROM costes_mantenimiento
    UNION ALL
    SELECT * FROM costes_genericos
)
INSERT INTO oltp_finanzas.coste_operativo
(id_coste_operativo, id_centro_coste, id_mantenimiento, fecha_coste, tipo_coste, importe, descripcion)
SELECT
    ROW_NUMBER() OVER (ORDER BY fecha_coste, id_centro_coste, COALESCE(id_mantenimiento, 0)) AS id_coste_operativo,
    id_centro_coste,
    id_mantenimiento,
    fecha_coste,
    tipo_coste,
    importe,
    descripcion
FROM todos_costes;

INSERT INTO oltp_finanzas.presupuesto
(id_presupuesto, id_centro_coste, periodo_inicio, periodo_fin, importe_presupuestado, observaciones)
SELECT
    ROW_NUMBER() OVER (ORDER BY cc.id_centro_coste, y.anio, q.trimestre) AS id_presupuesto,
    cc.id_centro_coste,
    q.periodo_inicio,
    q.periodo_fin,
    ROUND((
        CASE cc.categoria_centro
            WHEN 'alojamiento' THEN 45000
            WHEN 'restauracion' THEN 22000
            WHEN 'mantenimiento' THEN 14000
            ELSE 12000
        END
        * (1 + (cc.id_hotel * 0.03))
        * (CASE q.trimestre
            WHEN 1 THEN 0.90
            WHEN 2 THEN 1.00
            WHEN 3 THEN 1.20
            ELSE 0.95
        END)
        * (CASE y.anio
            WHEN 2023 THEN 1.00
            WHEN 2024 THEN 1.05
            ELSE 1.09
        END)
    )::NUMERIC, 2) AS importe_presupuestado,
    'Presupuesto trimestral ' || y.anio || ' T' || q.trimestre AS observaciones
FROM oltp_finanzas.centro_coste cc
CROSS JOIN (VALUES (2023), (2024), (2025)) AS y(anio)
CROSS JOIN LATERAL (
    VALUES
        (1, make_date(y.anio, 1, 1),  make_date(y.anio, 3, 31)),
        (2, make_date(y.anio, 4, 1),  make_date(y.anio, 6, 30)),
        (3, make_date(y.anio, 7, 1),  make_date(y.anio, 9, 30)),
        (4, make_date(y.anio,10, 1),  make_date(y.anio,12, 31))
) AS q(trimestre, periodo_inicio, periodo_fin);

SELECT setval('oltp_finanzas.centro_coste_id_centro_coste_seq', (SELECT MAX(id_centro_coste) FROM oltp_finanzas.centro_coste), true);
SELECT setval('oltp_finanzas.factura_id_factura_seq', (SELECT MAX(id_factura) FROM oltp_finanzas.factura), true);
SELECT setval('oltp_finanzas.linea_factura_id_linea_factura_seq', (SELECT MAX(id_linea_factura) FROM oltp_finanzas.linea_factura), true);
SELECT setval('oltp_finanzas.coste_operativo_id_coste_operativo_seq', (SELECT MAX(id_coste_operativo) FROM oltp_finanzas.coste_operativo), true);
SELECT setval('oltp_finanzas.presupuesto_id_presupuesto_seq', (SELECT MAX(id_presupuesto) FROM oltp_finanzas.presupuesto), true);
