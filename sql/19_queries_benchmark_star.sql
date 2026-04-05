-- =========================================
-- Benchmark Star Schema
-- Royal Whisper Resorts
-- 5 consultas analíticas de referencia
-- Q1 = roll up temporal
-- Q2 = drill down ocupación
-- =========================================

\echo '--- Q1 ---'
-- Q1. Evolución de reservas e ingresos por hotel y trimestre (roll up)
SELECT
    t.anio,
    t.trimestre,
    h.nombre_hotel,
    COUNT(*) AS total_reservas,
    SUM(f.importe_reserva) AS total_ingresos
FROM olap.fact_reservas f
JOIN olap.dim_tiempo t
    ON f.tiempo_sk = t.tiempo_sk
JOIN olap.dim_hotel h
    ON f.hotel_sk = h.hotel_sk
GROUP BY t.anio, t.trimestre, h.nombre_hotel
ORDER BY t.anio, t.trimestre, h.nombre_hotel;

\echo '--- Q2 ---'
-- Q2. Ocupación por tipo de habitación y temporada (drill down)
SELECT
    h.nombre_hotel,
    ta.nombre_temporada,
    hb.tipo_habitacion,
    SUM(f.noches_ocupadas) AS noches_ocupadas
FROM olap.fact_estancias f
JOIN olap.dim_hotel h
    ON f.hotel_sk = h.hotel_sk
JOIN olap.dim_habitacion hb
    ON f.habitacion_sk = hb.habitacion_sk
JOIN olap.dim_tarifa ta
    ON f.tarifa_sk = ta.tarifa_sk
GROUP BY h.nombre_hotel, ta.nombre_temporada, hb.tipo_habitacion
ORDER BY h.nombre_hotel, ta.nombre_temporada, hb.tipo_habitacion;

\echo '--- Q3 ---'
-- Q3. Ingresos y tasa de cancelación por tarifa
SELECT
    ta.paquete_contratado,
    ta.tipo_pension,
    COUNT(*) AS total_reservas,
    SUM(f.importe_reserva) AS total_ingresos,
    AVG(CASE WHEN f.cancelada THEN 1.0 ELSE 0.0 END) AS tasa_cancelacion
FROM olap.fact_reservas f
JOIN olap.dim_tarifa ta
    ON f.tarifa_sk = ta.tarifa_sk
GROUP BY ta.paquete_contratado, ta.tipo_pension
ORDER BY total_ingresos DESC;

\echo '--- Q4 ---'
-- Q4. Rendimiento global de los hoteles
WITH reservas_hotel AS (
    SELECT
        hotel_sk,
        COUNT(*) AS total_reservas,
        SUM(importe_reserva) AS ingresos_reservas
    FROM olap.fact_reservas
    GROUP BY hotel_sk
),
servicios_hotel AS (
    SELECT
        hotel_sk,
        SUM(importe_servicio) AS ingresos_servicios
    FROM olap.fact_servicios
    GROUP BY hotel_sk
)
SELECT
    h.nombre_hotel,
    COALESCE(rh.total_reservas, 0) AS total_reservas,
    COALESCE(rh.ingresos_reservas, 0) AS ingresos_reservas,
    COALESCE(sh.ingresos_servicios, 0) AS ingresos_servicios,
    COALESCE(rh.ingresos_reservas, 0) + COALESCE(sh.ingresos_servicios, 0) AS rendimiento_total
FROM olap.dim_hotel h
LEFT JOIN reservas_hotel rh
    ON h.hotel_sk = rh.hotel_sk
LEFT JOIN servicios_hotel sh
    ON h.hotel_sk = sh.hotel_sk
ORDER BY rendimiento_total DESC;

\echo '--- Q5 ---'
-- Q5. Servicios complementarios por hotel y tipo de cliente
SELECT
    h.nombre_hotel,
    c.tipo_cliente,
    s.nombre_servicio,
    SUM(f.cantidad) AS total_consumido,
    SUM(f.importe_servicio) AS total_ingresos
FROM olap.fact_servicios f
JOIN olap.dim_hotel h
    ON f.hotel_sk = h.hotel_sk
JOIN olap.dim_cliente c
    ON f.cliente_sk = c.cliente_sk
JOIN olap.dim_servicio s
    ON f.servicio_sk = s.servicio_sk
GROUP BY h.nombre_hotel, c.tipo_cliente, s.nombre_servicio
ORDER BY total_ingresos DESC;

\echo '--- Q6 ---'
SELECT
    t.anio,
    t.trimestre,
    h.comunidad_autonoma,
    COUNT(*) AS total_reservas,
    SUM(f.importe_reserva) AS total_ingresos
FROM olap.fact_reservas f
JOIN olap.dim_tiempo t
    ON f.tiempo_sk = t.tiempo_sk
JOIN olap.dim_hotel h
    ON f.hotel_sk = h.hotel_sk
GROUP BY t.anio, t.trimestre, h.comunidad_autonoma
ORDER BY t.anio, t.trimestre, h.comunidad_autonoma;
