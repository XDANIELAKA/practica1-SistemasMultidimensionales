-- =========================================
-- Benchmark OLTP
-- Royal Whisper Resorts
-- 5 consultas analíticas de referencia
-- Q1 = roll up temporal
-- Q2 = drill down ocupación
-- =========================================

-- Q1. Evolución de reservas e ingresos por hotel y trimestre (roll up)
\echo '--- Q1 ---'
SELECT
    EXTRACT(YEAR FROM r.fecha_reserva) AS anio,
    EXTRACT(QUARTER FROM r.fecha_reserva) AS trimestre,
    h.nombre_hotel,
    COUNT(*) AS total_reservas,
    SUM(dr.importe_previsto) AS total_ingresos
FROM oltp_reservas.reserva r
JOIN oltp_reservas.detalle_reserva dr
    ON r.id_reserva = dr.id_reserva
JOIN oltp_alojamientos.hotel h
    ON dr.id_hotel = h.id_hotel
GROUP BY
    EXTRACT(YEAR FROM r.fecha_reserva),
    EXTRACT(QUARTER FROM r.fecha_reserva),
    h.nombre_hotel
ORDER BY anio, trimestre, h.nombre_hotel;

\echo '--- Q2 ---'
-- Q2. Ocupación por tipo de habitación y temporada (drill down)
SELECT
    h.nombre_hotel,
    tp.nombre_temporada,
    th.nombre_tipo AS tipo_habitacion,
    SUM(dr.noches_reservadas) AS noches_ocupadas
FROM oltp_reservas.detalle_reserva dr
JOIN oltp_reservas.reserva r
    ON dr.id_reserva = r.id_reserva
JOIN oltp_alojamientos.hotel h
    ON dr.id_hotel = h.id_hotel
JOIN oltp_alojamientos.tarifa ta
    ON dr.id_tarifa = ta.id_tarifa
JOIN oltp_alojamientos.tipo_habitacion th
    ON ta.id_tipo_habitacion = th.id_tipo_habitacion
JOIN oltp_alojamientos.temporada tp
    ON ta.id_temporada = tp.id_temporada
WHERE r.estado_reserva <> 'cancelada'
GROUP BY h.nombre_hotel, tp.nombre_temporada, th.nombre_tipo
ORDER BY h.nombre_hotel, tp.nombre_temporada, th.nombre_tipo;

\echo '--- Q3 ---'
-- Q3. Ingresos y tasa de cancelación por tarifa
SELECT
    ta.paquete_contratado,
    ta.tipo_pension,
    COUNT(*) AS total_reservas,
    SUM(dr.importe_previsto) AS total_ingresos,
    AVG(CASE WHEN r.estado_reserva = 'cancelada' THEN 1.0 ELSE 0.0 END) AS tasa_cancelacion
FROM oltp_reservas.reserva r
JOIN oltp_reservas.detalle_reserva dr
    ON r.id_reserva = dr.id_reserva
JOIN oltp_alojamientos.tarifa ta
    ON dr.id_tarifa = ta.id_tarifa
GROUP BY ta.paquete_contratado, ta.tipo_pension
ORDER BY total_ingresos DESC;

\echo '--- Q4 ---'
-- Q4. Rendimiento global de los hoteles
WITH reservas_hotel AS (
    SELECT
        dr.id_hotel,
        COUNT(*) AS total_reservas,
        SUM(dr.importe_previsto) AS ingresos_reservas
    FROM oltp_reservas.detalle_reserva dr
    JOIN oltp_reservas.reserva r
        ON dr.id_reserva = r.id_reserva
    GROUP BY dr.id_hotel
),
servicios_hotel AS (
    SELECT
        cs.id_hotel,
        SUM(cs.importe_total) AS ingresos_servicios
    FROM oltp_operaciones.consumo_servicio cs
    GROUP BY cs.id_hotel
)
SELECT
    h.nombre_hotel,
    COALESCE(rh.total_reservas, 0) AS total_reservas,
    COALESCE(rh.ingresos_reservas, 0) AS ingresos_reservas,
    COALESCE(sh.ingresos_servicios, 0) AS ingresos_servicios,
    COALESCE(rh.ingresos_reservas, 0) + COALESCE(sh.ingresos_servicios, 0) AS rendimiento_total
FROM oltp_alojamientos.hotel h
LEFT JOIN reservas_hotel rh
    ON h.id_hotel = rh.id_hotel
LEFT JOIN servicios_hotel sh
    ON h.id_hotel = sh.id_hotel
ORDER BY rendimiento_total DESC;

\echo '--- Q5 ---'
-- Q5. Servicios complementarios por hotel y tipo de cliente
SELECT
    h.nombre_hotel,
    c.tipo_cliente,
    s.nombre_servicio,
    SUM(cs.cantidad) AS total_consumido,
    SUM(cs.importe_total) AS total_ingresos
FROM oltp_operaciones.consumo_servicio cs
JOIN oltp_reservas.reserva r
    ON cs.id_reserva = r.id_reserva
JOIN oltp_reservas.cliente c
    ON r.id_cliente = c.id_cliente
JOIN oltp_alojamientos.hotel h
    ON cs.id_hotel = h.id_hotel
JOIN oltp_operaciones.servicio s
    ON cs.id_servicio = s.id_servicio
GROUP BY h.nombre_hotel, c.tipo_cliente, s.nombre_servicio
ORDER BY total_ingresos DESC;

\echo '--- Q6 ---'
SELECT
    EXTRACT(YEAR FROM r.fecha_reserva) AS anio,
    EXTRACT(QUARTER FROM r.fecha_reserva) AS trimestre,
    h.comunidad_autonoma,
    COUNT(*) AS total_reservas,
    SUM(dr.importe_previsto) AS total_ingresos
FROM oltp_reservas.reserva r
JOIN oltp_reservas.detalle_reserva dr
    ON r.id_reserva = dr.id_reserva
JOIN oltp_alojamientos.hotel h
    ON dr.id_hotel = h.id_hotel
GROUP BY
    EXTRACT(YEAR FROM r.fecha_reserva),
    EXTRACT(QUARTER FROM r.fecha_reserva),
    h.comunidad_autonoma
ORDER BY anio, trimestre, h.comunidad_autonoma;
