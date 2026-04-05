INSERT INTO olap.dim_tiempo
(fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia, temporada)
SELECT DISTINCT
    d.fecha,
    EXTRACT(YEAR FROM d.fecha)::INT AS anio,
    EXTRACT(QUARTER FROM d.fecha)::INT AS trimestre,
    EXTRACT(MONTH FROM d.fecha)::INT AS mes,
    CASE EXTRACT(MONTH FROM d.fecha)::INT
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS nombre_mes,
    EXTRACT(DAY FROM d.fecha)::INT AS dia,
    EXTRACT(ISODOW FROM d.fecha)::INT AS dia_semana,
    CASE EXTRACT(ISODOW FROM d.fecha)::INT
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS nombre_dia,
    CASE
        WHEN EXTRACT(MONTH FROM d.fecha)::INT IN (12, 1, 2) THEN 'Invierno'
        WHEN EXTRACT(MONTH FROM d.fecha)::INT IN (3, 4, 5) THEN 'Primavera'
        WHEN EXTRACT(MONTH FROM d.fecha)::INT IN (6, 7, 8) THEN 'Verano'
        ELSE 'Otoño'
    END AS temporada
FROM (
    SELECT fecha_reserva AS fecha FROM oltp_reservas.reserva
    UNION
    SELECT fecha_entrada FROM oltp_reservas.detalle_reserva
    UNION
    SELECT fecha_salida FROM oltp_reservas.detalle_reserva
    UNION
    SELECT fecha_pago FROM oltp_reservas.pago_reserva
    UNION
    SELECT fecha_consumo FROM oltp_operaciones.consumo_servicio
    UNION
    SELECT fecha_apertura FROM oltp_operaciones.incidencia
    UNION
    SELECT fecha_cierre FROM oltp_operaciones.incidencia WHERE fecha_cierre IS NOT NULL
    UNION
    SELECT fecha_mantenimiento FROM oltp_operaciones.mantenimiento
    UNION
    SELECT fecha_alta FROM oltp_rrhh.empleado
    UNION
    SELECT fecha_inicio FROM oltp_rrhh.contrato
    UNION
    SELECT fecha_fin FROM oltp_rrhh.contrato WHERE fecha_fin IS NOT NULL
    UNION
    SELECT fecha_turno FROM oltp_rrhh.turno
    UNION
    SELECT fecha_inicio_asignacion FROM oltp_rrhh.asignacion_hotel
    UNION
    SELECT fecha_fin_asignacion FROM oltp_rrhh.asignacion_hotel WHERE fecha_fin_asignacion IS NOT NULL
    UNION
    SELECT fecha_factura FROM oltp_finanzas.factura
    UNION
    SELECT fecha_coste FROM oltp_finanzas.coste_operativo
    UNION
    SELECT periodo_inicio FROM oltp_finanzas.presupuesto
    UNION
    SELECT periodo_fin FROM oltp_finanzas.presupuesto
) d
ORDER BY d.fecha;

INSERT INTO olap.dim_hotel
(hotel_id, nombre_hotel, categoria, ciudad, provincia, comunidad_autonoma, fecha_apertura, activo)
SELECT
    id_hotel,
    nombre_hotel,
    categoria,
    ciudad,
    provincia,
    comunidad_autonoma,
    fecha_apertura,
    activo
FROM oltp_alojamientos.hotel
ORDER BY id_hotel;

INSERT INTO olap.dim_cliente
(cliente_id, nombre, apellidos, nombre_completo, pais, comunidad_autonoma, ciudad, tipo_cliente, fecha_registro)
SELECT
    id_cliente,
    nombre,
    apellidos,
    nombre || ' ' || apellidos AS nombre_completo,
    pais,
    comunidad_autonoma,
    ciudad,
    tipo_cliente,
    fecha_registro
FROM oltp_reservas.cliente
ORDER BY id_cliente;

INSERT INTO olap.dim_canal_reserva
(canal_reserva_id, nombre_canal, tipo_canal, comision, activo)
SELECT
    id_canal_reserva,
    nombre_canal,
    tipo_canal,
    comision,
    activo
FROM oltp_reservas.canal_reserva
ORDER BY id_canal_reserva;

INSERT INTO olap.dim_habitacion
(habitacion_id, hotel_id, tipo_habitacion_id, numero_habitacion, planta, vista, estado_habitacion, tipo_habitacion, capacidad_maxima, metros_cuadrados)
SELECT
    h.id_habitacion,
    h.id_hotel,
    h.id_tipo_habitacion,
    h.numero_habitacion,
    h.planta,
    h.vista,
    h.estado_habitacion,
    th.nombre_tipo,
    th.capacidad_maxima,
    th.metros_cuadrados
FROM oltp_alojamientos.habitacion h
JOIN oltp_alojamientos.tipo_habitacion th
    ON h.id_tipo_habitacion = th.id_tipo_habitacion
ORDER BY h.id_habitacion;

INSERT INTO olap.dim_tarifa
(tarifa_id, hotel_id, tipo_habitacion_id, temporada_id, nombre_tarifa, tipo_habitacion, nombre_temporada, tipo_pension, paquete_contratado, precio_noche, moneda)
SELECT
    t.id_tarifa,
    t.id_hotel,
    t.id_tipo_habitacion,
    t.id_temporada,
    t.nombre_tarifa,
    th.nombre_tipo,
    tp.nombre_temporada,
    t.tipo_pension,
    t.paquete_contratado,
    t.precio_noche,
    t.moneda
FROM oltp_alojamientos.tarifa t
JOIN oltp_alojamientos.tipo_habitacion th
    ON t.id_tipo_habitacion = th.id_tipo_habitacion
JOIN oltp_alojamientos.temporada tp
    ON t.id_temporada = tp.id_temporada
ORDER BY t.id_tarifa;

INSERT INTO olap.dim_servicio
(servicio_id, nombre_servicio, categoria_servicio, precio_base, activo)
SELECT
    id_servicio,
    nombre_servicio,
    categoria_servicio,
    precio_base,
    activo
FROM oltp_operaciones.servicio
ORDER BY id_servicio;
