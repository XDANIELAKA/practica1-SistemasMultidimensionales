BEGIN;

TRUNCATE TABLE olap.fact_servicios RESTART IDENTITY;
TRUNCATE TABLE olap.fact_estancias RESTART IDENTITY;
TRUNCATE TABLE olap.fact_reservas RESTART IDENTITY;

INSERT INTO olap.fact_reservas
(
    tiempo_sk,
    hotel_sk,
    cliente_sk,
    canal_reserva_sk,
    tarifa_sk,
    reserva_id,
    noches_reservadas,
    importe_reserva,
    cancelada,
    total_pagado
)
SELECT
    dt.tiempo_sk,
    dh.hotel_sk,
    dc.cliente_sk,
    dcr.canal_reserva_sk,
    dta.tarifa_sk,
    r.id_reserva,
    dr.noches_reservadas,
    dr.importe_previsto,
    CASE
        WHEN r.estado_reserva = 'cancelada' THEN TRUE
        ELSE FALSE
    END AS cancelada,
    COALESCE(p.total_pagado, 0) AS total_pagado
FROM oltp_reservas.reserva r
JOIN oltp_reservas.detalle_reserva dr
    ON r.id_reserva = dr.id_reserva
LEFT JOIN (
    SELECT
        id_reserva,
        SUM(importe_pagado) AS total_pagado
    FROM oltp_reservas.pago_reserva
    WHERE estado_pago = 'pagado'
    GROUP BY id_reserva
) p
    ON r.id_reserva = p.id_reserva
JOIN olap.dim_tiempo dt
    ON dt.fecha = r.fecha_reserva
JOIN olap.dim_hotel dh
    ON dh.hotel_id = dr.id_hotel
JOIN olap.dim_cliente dc
    ON dc.cliente_id = r.id_cliente
JOIN olap.dim_canal_reserva dcr
    ON dcr.canal_reserva_id = r.id_canal_reserva
JOIN olap.dim_tarifa dta
    ON dta.tarifa_id = dr.id_tarifa;

WITH habitacion_representativa AS (
    SELECT
        hotel_id,
        tipo_habitacion,
        MIN(habitacion_sk) AS habitacion_sk
    FROM olap.dim_habitacion
    GROUP BY hotel_id, tipo_habitacion
)
INSERT INTO olap.fact_estancias
(
    tiempo_sk,
    hotel_sk,
    habitacion_sk,
    cliente_sk,
    tarifa_sk,
    detalle_reserva_id,
    noches_ocupadas,
    ingreso_alojamiento
)
SELECT
    dt.tiempo_sk,
    dh.hotel_sk,
    hr.habitacion_sk,
    dc.cliente_sk,
    dta.tarifa_sk,
    dr.id_detalle_reserva,
    dr.noches_reservadas,
    dr.importe_previsto
FROM oltp_reservas.detalle_reserva dr
JOIN oltp_reservas.reserva r
    ON dr.id_reserva = r.id_reserva
JOIN olap.dim_tiempo dt
    ON dt.fecha = dr.fecha_entrada
JOIN olap.dim_hotel dh
    ON dh.hotel_id = dr.id_hotel
JOIN olap.dim_cliente dc
    ON dc.cliente_id = r.id_cliente
JOIN olap.dim_tarifa dta
    ON dta.tarifa_id = dr.id_tarifa
JOIN habitacion_representativa hr
    ON hr.hotel_id = dta.hotel_id
   AND hr.tipo_habitacion = dta.tipo_habitacion
WHERE r.estado_reserva <> 'cancelada';

INSERT INTO olap.fact_servicios
(
    tiempo_sk,
    hotel_sk,
    cliente_sk,
    servicio_sk,
    consumo_servicio_id,
    cantidad,
    importe_servicio
)
SELECT
    dt.tiempo_sk,
    dh.hotel_sk,
    dc.cliente_sk,
    ds.servicio_sk,
    cs.id_consumo_servicio,
    cs.cantidad,
    cs.importe_total
FROM oltp_operaciones.consumo_servicio cs
JOIN oltp_reservas.reserva r
    ON cs.id_reserva = r.id_reserva
JOIN olap.dim_tiempo dt
    ON dt.fecha = cs.fecha_consumo
JOIN olap.dim_hotel dh
    ON dh.hotel_id = cs.id_hotel
JOIN olap.dim_cliente dc
    ON dc.cliente_id = r.id_cliente
JOIN olap.dim_servicio ds
    ON ds.servicio_id = cs.id_servicio;

COMMIT;
