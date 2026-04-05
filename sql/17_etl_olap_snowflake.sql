BEGIN;

TRUNCATE TABLE olap_snow.fact_servicios RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.fact_estancias RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.fact_reservas RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_hotel RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_geografia RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_tarifa RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_habitacion RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_servicio RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_canal_reserva RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_cliente RESTART IDENTITY CASCADE;
TRUNCATE TABLE olap_snow.dim_tiempo RESTART IDENTITY CASCADE;

INSERT INTO olap_snow.dim_tiempo
(fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia, temporada)
SELECT fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia, temporada
FROM olap.dim_tiempo;

INSERT INTO olap_snow.dim_cliente
(cliente_id, nombre, apellidos, nombre_completo, pais, comunidad_autonoma, ciudad, tipo_cliente, fecha_registro)
SELECT cliente_id, nombre, apellidos, nombre_completo, pais, comunidad_autonoma, ciudad, tipo_cliente, fecha_registro
FROM olap.dim_cliente;

INSERT INTO olap_snow.dim_canal_reserva
(canal_reserva_id, nombre_canal, tipo_canal, comision)
SELECT canal_reserva_id, nombre_canal, tipo_canal, comision
FROM olap.dim_canal_reserva;

INSERT INTO olap_snow.dim_servicio
(servicio_id, nombre_servicio, categoria_servicio, precio_base, activo)
SELECT servicio_id, nombre_servicio, categoria_servicio, precio_base, activo
FROM olap.dim_servicio;

INSERT INTO olap_snow.dim_habitacion
(habitacion_id, hotel_id, numero_habitacion, planta, estado_habitacion, tipo_habitacion, capacidad_maxima)
SELECT habitacion_id, hotel_id, numero_habitacion, planta, estado_habitacion, tipo_habitacion, capacidad_maxima
FROM olap.dim_habitacion;

INSERT INTO olap_snow.dim_tarifa
(tarifa_id, hotel_id, tipo_habitacion, nombre_temporada, tipo_pension, paquete_contratado, precio_noche)
SELECT tarifa_id, hotel_id, tipo_habitacion, nombre_temporada, tipo_pension, paquete_contratado, precio_noche
FROM olap.dim_tarifa;

INSERT INTO olap_snow.dim_geografia
(ciudad, provincia, comunidad_autonoma)
SELECT DISTINCT ciudad, provincia, comunidad_autonoma
FROM olap.dim_hotel;

INSERT INTO olap_snow.dim_hotel
(hotel_id, nombre_hotel, categoria, geografia_sk)
SELECT
    h.hotel_id,
    h.nombre_hotel,
    h.categoria,
    g.geografia_sk
FROM olap.dim_hotel h
JOIN olap_snow.dim_geografia g
  ON h.ciudad = g.ciudad
 AND h.provincia = g.provincia
 AND h.comunidad_autonoma = g.comunidad_autonoma;

INSERT INTO olap_snow.fact_reservas
(tiempo_sk, hotel_sk, cliente_sk, canal_reserva_sk, tarifa_sk,
 reserva_id, noches_reservadas, importe_reserva, cancelada, total_pagado)
SELECT
    dt2.tiempo_sk,
    dh2.hotel_sk,
    dc2.cliente_sk,
    dcr2.canal_reserva_sk,
    dta2.tarifa_sk,
    f.reserva_id,
    f.noches_reservadas,
    f.importe_reserva,
    f.cancelada,
    f.total_pagado
FROM olap.fact_reservas f
JOIN olap.dim_tiempo dt ON f.tiempo_sk = dt.tiempo_sk
JOIN olap_snow.dim_tiempo dt2 ON dt.fecha = dt2.fecha
JOIN olap.dim_hotel dh ON f.hotel_sk = dh.hotel_sk
JOIN olap_snow.dim_hotel dh2 ON dh.hotel_id = dh2.hotel_id
JOIN olap.dim_cliente dc ON f.cliente_sk = dc.cliente_sk
JOIN olap_snow.dim_cliente dc2 ON dc.cliente_id = dc2.cliente_id
JOIN olap.dim_canal_reserva dcr ON f.canal_reserva_sk = dcr.canal_reserva_sk
JOIN olap_snow.dim_canal_reserva dcr2 ON dcr.canal_reserva_id = dcr2.canal_reserva_id
JOIN olap.dim_tarifa dta ON f.tarifa_sk = dta.tarifa_sk
JOIN olap_snow.dim_tarifa dta2 ON dta.tarifa_id = dta2.tarifa_id;

INSERT INTO olap_snow.fact_estancias
(tiempo_sk, hotel_sk, habitacion_sk, cliente_sk, tarifa_sk,
 detalle_reserva_id, noches_ocupadas, ingreso_alojamiento)
SELECT
    dt2.tiempo_sk,
    dh2.hotel_sk,
    dhab2.habitacion_sk,
    dc2.cliente_sk,
    dta2.tarifa_sk,
    f.detalle_reserva_id,
    f.noches_ocupadas,
    f.ingreso_alojamiento
FROM olap.fact_estancias f
JOIN olap.dim_tiempo dt ON f.tiempo_sk = dt.tiempo_sk
JOIN olap_snow.dim_tiempo dt2 ON dt.fecha = dt2.fecha
JOIN olap.dim_hotel dh ON f.hotel_sk = dh.hotel_sk
JOIN olap_snow.dim_hotel dh2 ON dh.hotel_id = dh2.hotel_id
JOIN olap.dim_habitacion dhab ON f.habitacion_sk = dhab.habitacion_sk
JOIN olap_snow.dim_habitacion dhab2 ON dhab.habitacion_id = dhab2.habitacion_id
JOIN olap.dim_cliente dc ON f.cliente_sk = dc.cliente_sk
JOIN olap_snow.dim_cliente dc2 ON dc.cliente_id = dc2.cliente_id
JOIN olap.dim_tarifa dta ON f.tarifa_sk = dta.tarifa_sk
JOIN olap_snow.dim_tarifa dta2 ON dta.tarifa_id = dta2.tarifa_id;

INSERT INTO olap_snow.fact_servicios
(tiempo_sk, hotel_sk, cliente_sk, servicio_sk,
 consumo_servicio_id, cantidad, importe_servicio)
SELECT
    dt2.tiempo_sk,
    dh2.hotel_sk,
    dc2.cliente_sk,
    ds2.servicio_sk,
    f.consumo_servicio_id,
    f.cantidad,
    f.importe_servicio
FROM olap.fact_servicios f
JOIN olap.dim_tiempo dt ON f.tiempo_sk = dt.tiempo_sk
JOIN olap_snow.dim_tiempo dt2 ON dt.fecha = dt2.fecha
JOIN olap.dim_hotel dh ON f.hotel_sk = dh.hotel_sk
JOIN olap_snow.dim_hotel dh2 ON dh.hotel_id = dh2.hotel_id
JOIN olap.dim_cliente dc ON f.cliente_sk = dc.cliente_sk
JOIN olap_snow.dim_cliente dc2 ON dc.cliente_id = dc2.cliente_id
JOIN olap.dim_servicio ds ON f.servicio_sk = ds.servicio_sk
JOIN olap_snow.dim_servicio ds2 ON ds.servicio_id = ds2.servicio_id;

COMMIT;
