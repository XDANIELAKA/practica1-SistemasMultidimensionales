INSERT INTO oltp_reservas.cliente
(id_cliente, nombre, apellidos, email, telefono, pais, comunidad_autonoma, ciudad, tipo_cliente, fecha_registro)
SELECT
    gs AS id_cliente,
    (ARRAY['Lucía','Carlos','Ana','Sergio','Marta','Javier','Elena','Pablo','Carmen','David','Irene','Raúl','Nuria','Álvaro','Paula','Diego','Marina','Iván','Sara','Hugo'])[((gs - 1) % 20) + 1] AS nombre,
    (ARRAY['Martín Pérez','Ruiz Gómez','López Sánchez','Torres Díaz','Navarro Gil','Santos León','Moreno Ruiz','Vega Martín','Prieto López','Castro Ríos','Herrera Mora','Jiménez Soler','Romero Vidal','Molina Campos'])[((gs - 1) % 14) + 1] AS apellidos,
    'cliente' || gs || '@royalwhisper.test' AS email,
    CASE
        WHEN gs % 20 = 0 THEN '+33-' || LPAD((600000000 + gs * 17)::TEXT, 9, '0')
        WHEN gs % 20 = 1 THEN '+44-' || LPAD((700000000 + gs * 19)::TEXT, 9, '0')
        WHEN gs % 20 = 2 THEN '+49-' || LPAD((500000000 + gs * 23)::TEXT, 9, '0')
        WHEN gs % 20 = 3 THEN '+31-' || LPAD((400000000 + gs * 29)::TEXT, 9, '0')
        WHEN gs % 20 = 4 THEN '+39-' || LPAD((300000000 + gs * 31)::TEXT, 9, '0')
        WHEN gs % 20 = 5 THEN '+351-' || LPAD((200000000 + gs * 37)::TEXT, 9, '0')
        WHEN gs % 20 = 6 THEN '+353-' || LPAD((100000000 + gs * 41)::TEXT, 9, '0')
        WHEN gs % 20 = 7 THEN '+1-' || LPAD((800000000 + gs * 43)::TEXT, 9, '0')
        ELSE '+34-' || LPAD((600000000 + gs * 47)::TEXT, 9, '0')
    END AS telefono,
    CASE
        WHEN gs % 20 = 0 THEN 'Francia'
        WHEN gs % 20 = 1 THEN 'Reino Unido'
        WHEN gs % 20 = 2 THEN 'Alemania'
        WHEN gs % 20 = 3 THEN 'Países Bajos'
        WHEN gs % 20 = 4 THEN 'Italia'
        WHEN gs % 20 = 5 THEN 'Portugal'
        WHEN gs % 20 = 6 THEN 'Irlanda'
        WHEN gs % 20 = 7 THEN 'Estados Unidos'
        ELSE 'España'
    END AS pais,
    CASE
        WHEN gs % 20 BETWEEN 0 AND 7 THEN NULL
        ELSE (ARRAY['Andalucía','Madrid','Cataluña','Comunidad Valenciana','Canarias','País Vasco'])[((gs - 1) % 6) + 1]
    END AS comunidad_autonoma,
    CASE
        WHEN gs % 20 = 0 THEN 'París'
        WHEN gs % 20 = 1 THEN 'Londres'
        WHEN gs % 20 = 2 THEN 'Berlín'
        WHEN gs % 20 = 3 THEN 'Ámsterdam'
        WHEN gs % 20 = 4 THEN 'Milán'
        WHEN gs % 20 = 5 THEN 'Lisboa'
        WHEN gs % 20 = 6 THEN 'Dublín'
        WHEN gs % 20 = 7 THEN 'Miami'
        ELSE (ARRAY['Málaga','Sevilla','Madrid','Barcelona','Valencia','Adeje','Granada','Bilbao'])[((gs - 1) % 8) + 1]
    END AS ciudad,
    CASE
        WHEN gs % 9 = 0 THEN 'corporativo'
        WHEN gs % 4 = 0 THEN 'premium'
        ELSE 'estandar'
    END AS tipo_cliente,
    DATE '2022-01-01' + ((gs * 7) % 1150)
FROM generate_series(1, 180) AS gs;

INSERT INTO oltp_reservas.canal_reserva
(id_canal_reserva, nombre_canal, tipo_canal, comision, activo)
VALUES
(1, 'Web oficial', 'directo', 0.00, TRUE),
(2, 'Booking', 'ota', 15.00, TRUE),
(3, 'Expedia', 'ota', 14.00, TRUE),
(4, 'Agencia Costa Sol', 'agencia', 8.50, TRUE),
(5, 'Teléfono', 'telefonico', 0.00, TRUE),
(6, 'Recepción', 'directo', 0.00, TRUE),
(7, 'Acuerdo corporativo', 'corporativo', 5.00, TRUE),
(8, 'Atrápalo', 'ota', 13.00, FALSE);

WITH base_reserva AS (
    SELECT
        gs AS id_reserva,
        ((gs * 7 - 1) % 180) + 1 AS id_cliente,
        DATE '2023-01-05' + ((gs * 7) % 1000) AS fecha_reserva,
        'RWR-' || TO_CHAR(DATE '2023-01-05' + ((gs * 7) % 1000), 'YYYY') || '-' || LPAD(gs::TEXT, 5, '0') AS codigo_reserva,
        CASE
            WHEN gs % 12 = 0 THEN 'cancelada'
            WHEN gs % 17 = 0 THEN 'pendiente'
            WHEN gs % 4 = 0 THEN 'confirmada'
            ELSE 'completada'
        END AS estado_reserva,
        CASE
            WHEN gs % 17 = 0 THEN 'Reserva pendiente de confirmación final'
            WHEN gs % 12 = 0 THEN 'Cancelación registrada por cambio de planes'
            WHEN gs % 9 = 0 THEN 'Cliente con preferencias especiales'
            ELSE NULL
        END AS observaciones
    FROM generate_series(1, 420) AS gs
), reserva_con_cliente AS (
    SELECT
        br.*,
        c.tipo_cliente,
        CASE
            WHEN c.tipo_cliente = 'corporativo' AND br.id_reserva % 3 <> 0 THEN 7
            WHEN br.id_reserva % 9 = 0 THEN 5
            WHEN br.id_reserva % 7 = 0 THEN 4
            WHEN br.id_reserva % 5 = 0 THEN 3
            WHEN br.id_reserva % 4 = 0 THEN 2
            ELSE 1
        END AS id_canal_reserva
    FROM base_reserva br
    JOIN oltp_reservas.cliente c
      ON c.id_cliente = br.id_cliente
)
INSERT INTO oltp_reservas.reserva
(id_reserva, id_cliente, id_canal_reserva, codigo_reserva, fecha_reserva, estado_reserva, observaciones)
SELECT
    id_reserva,
    id_cliente,
    id_canal_reserva,
    codigo_reserva,
    fecha_reserva,
    estado_reserva,
    observaciones
FROM reserva_con_cliente;

WITH reserva_base AS (
    SELECT
        r.id_reserva,
        r.fecha_reserva,
        r.estado_reserva,
        c.tipo_cliente,
        ((r.id_reserva * 5 - 1) % 8) + 1 AS id_hotel,
        CASE
            WHEN c.tipo_cliente = 'corporativo' THEN CASE WHEN r.id_reserva % 5 = 0 THEN 2 ELSE 1 END
            WHEN c.tipo_cliente = 'premium' THEN 2 + (r.id_reserva % 3)
            ELSE 1 + (r.id_reserva % 4)
        END AS numero_huespedes,
        DATE '2023-01-05' + ((r.id_reserva * 7) % 1000) + ((r.id_reserva * 11) % 75 + 3) AS fecha_entrada,
        2 + (r.id_reserva % 9) AS noches_reservadas,
        CASE
            WHEN c.tipo_cliente = 'premium' AND (2 + (r.id_reserva % 3)) >= 3 THEN 5
            WHEN c.tipo_cliente = 'premium' THEN 4
            WHEN c.tipo_cliente = 'corporativo' AND (CASE WHEN r.id_reserva % 5 = 0 THEN 2 ELSE 1 END) = 1 THEN 1
            WHEN c.tipo_cliente = 'corporativo' THEN 2
            WHEN 1 + (r.id_reserva % 4) = 1 THEN 1
            WHEN 1 + (r.id_reserva % 4) = 2 THEN 2
            WHEN 1 + (r.id_reserva % 4) = 3 THEN 4
            ELSE 3
        END AS id_tipo_habitacion,
        CASE
            WHEN c.tipo_cliente = 'premium' OR r.id_reserva % 5 = 0 THEN 'flexible'
            ELSE 'no_reembolsable'
        END AS nombre_tarifa
    FROM oltp_reservas.reserva r
    JOIN oltp_reservas.cliente c
      ON c.id_cliente = r.id_cliente
), reserva_temporada AS (
    SELECT
        rb.*, 
        (rb.fecha_entrada + rb.noches_reservadas) AS fecha_salida,
        t.id_temporada
    FROM reserva_base rb
    JOIN oltp_alojamientos.temporada t
      ON rb.fecha_entrada BETWEEN t.fecha_inicio AND t.fecha_fin
), reserva_tarifa AS (
    SELECT
        rt.id_reserva,
        rt.id_hotel,
        ta.id_tarifa,
        rt.fecha_entrada,
        rt.fecha_salida,
        rt.numero_huespedes,
        rt.noches_reservadas,
        ROUND((rt.noches_reservadas * ta.precio_noche * CASE
            WHEN rt.numero_huespedes = 3 THEN 1.05
            WHEN rt.numero_huespedes >= 4 THEN 1.10
            ELSE 1.00
        END)::NUMERIC, 2) AS importe_previsto
    FROM reserva_temporada rt
    JOIN oltp_alojamientos.tarifa ta
      ON ta.id_hotel = rt.id_hotel
     AND ta.id_tipo_habitacion = rt.id_tipo_habitacion
     AND ta.id_temporada = rt.id_temporada
     AND ta.nombre_tarifa = rt.nombre_tarifa
)
INSERT INTO oltp_reservas.detalle_reserva
(id_detalle_reserva, id_reserva, id_hotel, id_tarifa, fecha_entrada, fecha_salida, numero_huespedes, noches_reservadas, importe_previsto)
SELECT
    id_reserva,
    id_reserva,
    id_hotel,
    id_tarifa,
    fecha_entrada,
    fecha_salida,
    numero_huespedes,
    noches_reservadas,
    importe_previsto
FROM reserva_tarifa;

WITH base_pago AS (
    SELECT r.id_reserva, r.estado_reserva, r.fecha_reserva, d.fecha_entrada, d.importe_previsto
    FROM oltp_reservas.reserva r
    JOIN oltp_reservas.detalle_reserva d
      ON d.id_reserva = r.id_reserva
)
INSERT INTO oltp_reservas.pago_reserva
(id_pago_reserva, id_reserva, fecha_pago, metodo_pago, importe_pagado, estado_pago, referencia_pago)
SELECT
    ROW_NUMBER() OVER (ORDER BY id_reserva, fase_pago, fecha_pago) AS id_pago_reserva,
    id_reserva,
    fecha_pago,
    metodo_pago,
    importe_pagado,
    estado_pago,
    referencia_pago
FROM (
    SELECT
        bp.id_reserva,
        1 AS fase_pago,
        bp.fecha_reserva AS fecha_pago,
        CASE (bp.id_reserva % 4)
            WHEN 0 THEN 'tarjeta'
            WHEN 1 THEN 'transferencia'
            WHEN 2 THEN 'bizum'
            ELSE 'efectivo'
        END AS metodo_pago,
        ROUND((bp.importe_previsto * 0.30)::NUMERIC, 2) AS importe_pagado,
        CASE
            WHEN bp.estado_reserva = 'pendiente' THEN 'pendiente'
            ELSE 'pagado'
        END AS estado_pago,
        'DEP-' || LPAD(bp.id_reserva::TEXT, 6, '0') AS referencia_pago
    FROM base_pago bp
    WHERE bp.estado_reserva <> 'cancelada' OR bp.id_reserva % 2 = 0

    UNION ALL

    SELECT
        bp.id_reserva,
        2 AS fase_pago,
        bp.fecha_entrada - 2 AS fecha_pago,
        CASE (bp.id_reserva % 4)
            WHEN 0 THEN 'tarjeta'
            WHEN 1 THEN 'transferencia'
            WHEN 2 THEN 'bizum'
            ELSE 'efectivo'
        END AS metodo_pago,
        ROUND((bp.importe_previsto * 0.70)::NUMERIC, 2) AS importe_pagado,
        CASE
            WHEN bp.estado_reserva = 'confirmada' AND bp.id_reserva % 6 = 0 THEN 'pendiente'
            ELSE 'pagado'
        END AS estado_pago,
        'FIN-' || LPAD(bp.id_reserva::TEXT, 6, '0') AS referencia_pago
    FROM base_pago bp
    WHERE bp.estado_reserva IN ('confirmada', 'completada')

    UNION ALL

    SELECT
        bp.id_reserva,
        3 AS fase_pago,
        bp.fecha_reserva + 10 AS fecha_pago,
        'transferencia' AS metodo_pago,
        ROUND((bp.importe_previsto * 0.30)::NUMERIC, 2) AS importe_pagado,
        'reembolsado' AS estado_pago,
        'REF-' || LPAD(bp.id_reserva::TEXT, 6, '0') AS referencia_pago
    FROM base_pago bp
    WHERE bp.estado_reserva = 'cancelada' AND bp.id_reserva % 2 = 0
) pagos;

SELECT setval('oltp_reservas.cliente_id_cliente_seq', (SELECT MAX(id_cliente) FROM oltp_reservas.cliente), true);
SELECT setval('oltp_reservas.canal_reserva_id_canal_reserva_seq', (SELECT MAX(id_canal_reserva) FROM oltp_reservas.canal_reserva), true);
SELECT setval('oltp_reservas.reserva_id_reserva_seq', (SELECT MAX(id_reserva) FROM oltp_reservas.reserva), true);
SELECT setval('oltp_reservas.detalle_reserva_id_detalle_reserva_seq', (SELECT MAX(id_detalle_reserva) FROM oltp_reservas.detalle_reserva), true);
SELECT setval('oltp_reservas.pago_reserva_id_pago_reserva_seq', (SELECT MAX(id_pago_reserva) FROM oltp_reservas.pago_reserva), true);
