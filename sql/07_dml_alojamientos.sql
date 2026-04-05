INSERT INTO oltp_alojamientos.hotel
(id_hotel, nombre_hotel, categoria, ciudad, provincia, comunidad_autonoma, fecha_apertura, activo)
VALUES
(1, 'Royal Whisper Marbella', 5, 'Marbella', 'Málaga', 'Andalucía', '2016-06-01', TRUE),
(2, 'Royal Whisper Sevilla', 4, 'Sevilla', 'Sevilla', 'Andalucía', '2017-03-15', TRUE),
(3, 'Royal Whisper Valencia', 4, 'Valencia', 'Valencia', 'Comunidad Valenciana', '2018-05-20', TRUE),
(4, 'Royal Whisper Palma', 5, 'Palma', 'Islas Baleares', 'Islas Baleares', '2015-04-10', TRUE),
(5, 'Royal Whisper Adeje', 5, 'Adeje', 'Santa Cruz de Tenerife', 'Canarias', '2019-07-01', TRUE),
(6, 'Royal Whisper Granada', 4, 'Granada', 'Granada', 'Andalucía', '2020-09-12', TRUE),
(7, 'Royal Whisper Barcelona', 4, 'Barcelona', 'Barcelona', 'Cataluña', '2018-11-08', TRUE),
(8, 'Royal Whisper San Sebastián', 5, 'San Sebastián', 'Guipúzcoa', 'País Vasco', '2021-02-18', TRUE);

INSERT INTO oltp_alojamientos.tipo_habitacion
(id_tipo_habitacion, nombre_tipo, capacidad_maxima, metros_cuadrados, descripcion)
VALUES
(1, 'individual', 1, 18.00, 'Habitación individual estándar'),
(2, 'doble', 2, 24.00, 'Habitación doble con cama de matrimonio o dos camas'),
(3, 'familiar', 4, 34.00, 'Habitación familiar con espacio ampliado'),
(4, 'junior_suite', 3, 42.00, 'Junior suite con zona de estar'),
(5, 'suite', 4, 58.00, 'Suite premium con terraza o vistas destacadas');

INSERT INTO oltp_alojamientos.temporada
(id_temporada, nombre_temporada, fecha_inicio, fecha_fin)
VALUES
(1, 'baja_2023', '2023-01-01', '2023-03-31'),
(2, 'media_2023', '2023-04-01', '2023-06-30'),
(3, 'alta_2023', '2023-07-01', '2023-09-30'),
(4, 'otoño_2023', '2023-10-01', '2023-12-31'),
(5, 'baja_2024', '2024-01-01', '2024-03-31'),
(6, 'media_2024', '2024-04-01', '2024-06-30'),
(7, 'alta_2024', '2024-07-01', '2024-09-30'),
(8, 'otoño_2024', '2024-10-01', '2024-12-31'),
(9, 'baja_2025', '2025-01-01', '2025-03-31'),
(10, 'media_2025', '2025-04-01', '2025-06-30'),
(11, 'alta_2025', '2025-07-01', '2025-09-30'),
(12, 'otoño_2025', '2025-10-01', '2025-12-31');

INSERT INTO oltp_alojamientos.habitacion
(id_habitacion, id_hotel, id_tipo_habitacion, numero_habitacion, planta, vista, estado_habitacion)
SELECT
    ((h.id_hotel - 1) * 16) + g.numero AS id_habitacion,
    h.id_hotel,
    CASE
        WHEN g.numero IN (1, 2, 3) THEN 1
        WHEN g.numero IN (4, 5, 6, 7, 8) THEN 2
        WHEN g.numero IN (9, 10, 11) THEN 3
        WHEN g.numero IN (12, 13, 14) THEN 4
        ELSE 5
    END AS id_tipo_habitacion,
    LPAD((((CASE
        WHEN g.numero <= 5 THEN 1
        WHEN g.numero <= 10 THEN 2
        ELSE 3
    END) * 100) + g.numero)::TEXT, 3, '0') AS numero_habitacion,
    CASE
        WHEN g.numero <= 5 THEN 1
        WHEN g.numero <= 10 THEN 2
        ELSE 3
    END AS planta,
    CASE ((g.numero - 1) % 5)
        WHEN 0 THEN 'mar'
        WHEN 1 THEN 'piscina'
        WHEN 2 THEN 'jardin'
        WHEN 3 THEN 'ciudad'
        ELSE 'montana'
    END AS vista,
    CASE
        WHEN g.numero = 16 AND h.id_hotel IN (2, 6) THEN 'mantenimiento'
        WHEN g.numero = 15 AND h.id_hotel IN (4, 8) THEN 'bloqueada'
        ELSE 'disponible'
    END AS estado_habitacion
FROM oltp_alojamientos.hotel h
CROSS JOIN generate_series(1, 16) AS g(numero);

INSERT INTO oltp_alojamientos.tarifa
(id_tarifa, id_hotel, id_tipo_habitacion, id_temporada, nombre_tarifa, tipo_pension, paquete_contratado, precio_noche, moneda)
SELECT
    ROW_NUMBER() OVER (ORDER BY h.id_hotel, th.id_tipo_habitacion, tp.id_temporada, tr.nombre_tarifa) AS id_tarifa,
    h.id_hotel,
    th.id_tipo_habitacion,
    tp.id_temporada,
    tr.nombre_tarifa,
    CASE
        WHEN h.id_hotel IN (4, 5) AND EXTRACT(MONTH FROM tp.fecha_inicio) = 7 THEN 'todo_incluido'
        WHEN th.id_tipo_habitacion IN (4, 5) THEN 'media_pension'
        WHEN th.id_tipo_habitacion = 3 THEN 'desayuno'
        WHEN tr.nombre_tarifa = 'flexible' THEN 'desayuno'
        ELSE 'solo_alojamiento'
    END AS tipo_pension,
    CASE
        WHEN h.id_hotel IN (4, 5) AND EXTRACT(MONTH FROM tp.fecha_inicio) = 7 THEN 'verano_resort'
        WHEN th.id_tipo_habitacion = 3 THEN 'familia_activa'
        WHEN th.id_tipo_habitacion IN (4, 5) THEN 'wellness_escape'
        ELSE NULL
    END AS paquete_contratado,
    ROUND((
        (CASE h.id_hotel
            WHEN 1 THEN 110
            WHEN 2 THEN 90
            WHEN 3 THEN 95
            WHEN 4 THEN 125
            WHEN 5 THEN 135
            WHEN 6 THEN 88
            WHEN 7 THEN 105
            ELSE 120
        END)
        * (CASE th.id_tipo_habitacion
            WHEN 1 THEN 1.00
            WHEN 2 THEN 1.22
            WHEN 3 THEN 1.58
            WHEN 4 THEN 2.00
            ELSE 2.75
        END)
        * (CASE EXTRACT(MONTH FROM tp.fecha_inicio)
            WHEN 1 THEN 0.85
            WHEN 4 THEN 1.00
            WHEN 7 THEN 1.38
            ELSE 1.08
        END)
        * (CASE tr.nombre_tarifa
            WHEN 'flexible' THEN 1.08
            ELSE 0.94
        END)
    )::NUMERIC, 2) AS precio_noche,
    'EUR' AS moneda
FROM oltp_alojamientos.hotel h
CROSS JOIN oltp_alojamientos.tipo_habitacion th
CROSS JOIN oltp_alojamientos.temporada tp
CROSS JOIN (VALUES ('flexible'), ('no_reembolsable')) AS tr(nombre_tarifa);

SELECT setval('oltp_alojamientos.hotel_id_hotel_seq', (SELECT MAX(id_hotel) FROM oltp_alojamientos.hotel), true);
SELECT setval('oltp_alojamientos.tipo_habitacion_id_tipo_habitacion_seq', (SELECT MAX(id_tipo_habitacion) FROM oltp_alojamientos.tipo_habitacion), true);
SELECT setval('oltp_alojamientos.temporada_id_temporada_seq', (SELECT MAX(id_temporada) FROM oltp_alojamientos.temporada), true);
SELECT setval('oltp_alojamientos.habitacion_id_habitacion_seq', (SELECT MAX(id_habitacion) FROM oltp_alojamientos.habitacion), true);
SELECT setval('oltp_alojamientos.tarifa_id_tarifa_seq', (SELECT MAX(id_tarifa) FROM oltp_alojamientos.tarifa), true);
