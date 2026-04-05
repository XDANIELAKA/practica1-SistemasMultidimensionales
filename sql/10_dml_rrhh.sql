INSERT INTO oltp_rrhh.departamento
(id_departamento, nombre_departamento, descripcion)
VALUES
(1, 'Recepción', 'Gestión de recepción y atención al cliente'),
(2, 'Pisos', 'Limpieza y acondicionamiento de habitaciones'),
(3, 'Mantenimiento', 'Soporte técnico y reparaciones'),
(4, 'Restauración', 'Restaurante, bares y room service'),
(5, 'Comercial', 'Reservas, ventas y acuerdos corporativos'),
(6, 'Administración', 'Gestión administrativa y control interno');

INSERT INTO oltp_rrhh.empleado
(id_empleado, id_departamento, nombre, apellidos, dni, telefono, email, fecha_alta, estado_empleado)
SELECT
    gs AS id_empleado,
    ((gs - 1) % 6) + 1 AS id_departamento,
    (ARRAY['María','Javier','Cristina','Diego','Patricia','Rubén','Laura','Francisco','Mónica','Iván','Sara','Miguel','Elisa','Alberto','Noelia','Daniel'])[((gs - 1) % 16) + 1] AS nombre,
    (ARRAY['Pérez Ruiz','Gómez Martín','López Díaz','Torres Gil','Santos León','Vega Campos','Morales Soler','Ramos Castro','Herrera Molina','Navarro Ríos','Ruiz Cano','Márquez Peña'])[((gs - 1) % 12) + 1] AS apellidos,
    LPAD((10000000 + gs)::TEXT, 8, '0') || SUBSTRING('TRWAGMYFPDXBNJZSQVHLCKE' FROM ((gs - 1) % 23) + 1 FOR 1) AS dni,
    '+34-' || LPAD((610000000 + gs * 29)::TEXT, 9, '0') AS telefono,
    'empleado' || gs || '@royalwhisperresorts.com' AS email,
    DATE '2022-01-01' + ((gs * 17) % 1250) AS fecha_alta,
    CASE
        WHEN gs % 19 = 0 THEN 'excedencia'
        WHEN gs % 14 = 0 THEN 'baja'
        ELSE 'activo'
    END AS estado_empleado
FROM generate_series(1, 72) AS gs;

INSERT INTO oltp_rrhh.contrato
(id_contrato, id_empleado, tipo_contrato, fecha_inicio, fecha_fin, salario_base, jornada)
SELECT
    gs AS id_contrato,
    e.id_empleado,
    CASE
        WHEN e.id_departamento = 5 AND e.id_empleado % 4 = 0 THEN 'indefinido'
        WHEN e.id_empleado % 8 = 0 THEN 'practicas'
        WHEN e.id_empleado % 6 = 0 THEN 'temporal'
        WHEN e.id_empleado % 5 = 0 THEN 'fijo_discontinuo'
        ELSE 'indefinido'
    END AS tipo_contrato,
    e.fecha_alta AS fecha_inicio,
    CASE
        WHEN e.id_empleado % 6 = 0 THEN e.fecha_alta + 365
        ELSE NULL
    END AS fecha_fin,
    ROUND((
        CASE e.id_departamento
            WHEN 1 THEN 1680
            WHEN 2 THEN 1450
            WHEN 3 THEN 1900
            WHEN 4 THEN 1600
            WHEN 5 THEN 1850
            ELSE 1750
        END
        + (e.id_empleado % 7) * 55
    )::NUMERIC, 2) AS salario_base,
    CASE
        WHEN e.id_empleado % 7 = 0 THEN 'parcial'
        ELSE 'completa'
    END AS jornada
FROM oltp_rrhh.empleado e
CROSS JOIN LATERAL (SELECT e.id_empleado AS gs) q;

WITH empleados_activos AS (
    SELECT id_empleado, id_departamento
    FROM oltp_rrhh.empleado
    WHERE estado_empleado = 'activo'
)
INSERT INTO oltp_rrhh.turno
(id_turno, id_empleado, fecha_turno, hora_inicio, hora_fin, tipo_turno)
SELECT
    ROW_NUMBER() OVER (ORDER BY ea.id_empleado, gs.n) AS id_turno,
    ea.id_empleado,
    DATE '2025-01-01' + ((ea.id_empleado * 7 + gs.n * 9) % 365) AS fecha_turno,
    CASE
        WHEN ea.id_departamento = 4 AND gs.n % 3 = 0 THEN TIME '15:00'
        WHEN ea.id_departamento = 1 AND gs.n % 4 = 0 THEN TIME '23:00'
        WHEN gs.n % 3 = 0 THEN TIME '15:00'
        ELSE TIME '07:00'
    END AS hora_inicio,
    CASE
        WHEN ea.id_departamento = 4 AND gs.n % 3 = 0 THEN TIME '23:00'
        WHEN ea.id_departamento = 1 AND gs.n % 4 = 0 THEN TIME '07:00'
        WHEN gs.n % 3 = 0 THEN TIME '23:00'
        ELSE TIME '15:00'
    END AS hora_fin,
    CASE
        WHEN ea.id_departamento = 1 AND gs.n % 4 = 0 THEN 'noche'
        WHEN gs.n % 3 = 0 THEN 'tarde'
        ELSE 'manana'
    END AS tipo_turno
FROM empleados_activos ea
CROSS JOIN generate_series(1, 12) AS gs(n);

INSERT INTO oltp_rrhh.asignacion_hotel
(id_asignacion_hotel, id_empleado, id_hotel, fecha_inicio_asignacion, fecha_fin_asignacion, puesto)
SELECT
    ROW_NUMBER() OVER (ORDER BY x.id_empleado, x.fecha_inicio_asignacion) AS id_asignacion_hotel,
    x.id_empleado,
    x.id_hotel,
    x.fecha_inicio_asignacion,
    x.fecha_fin_asignacion,
    x.puesto
FROM (
    SELECT
        e.id_empleado,
        ((e.id_empleado - 1) % 8) + 1 AS id_hotel,
        e.fecha_alta AS fecha_inicio_asignacion,
        NULL::DATE AS fecha_fin_asignacion,
        CASE e.id_departamento
            WHEN 1 THEN 'Recepcionista'
            WHEN 2 THEN 'Camarero de pisos'
            WHEN 3 THEN 'Técnico de mantenimiento'
            WHEN 4 THEN 'Personal de restauración'
            WHEN 5 THEN 'Agente comercial'
            ELSE 'Administrativo'
        END AS puesto
    FROM oltp_rrhh.empleado e

    UNION ALL

    SELECT
        e.id_empleado,
        CASE WHEN ((e.id_empleado - 1) % 8) + 1 = 8 THEN 1 ELSE ((e.id_empleado - 1) % 8) + 2 END AS id_hotel,
        e.fecha_alta - 180 AS fecha_inicio_asignacion,
        e.fecha_alta - 1 AS fecha_fin_asignacion,
        CASE e.id_departamento
            WHEN 1 THEN 'Recepcionista'
            WHEN 2 THEN 'Camarero de pisos'
            WHEN 3 THEN 'Técnico de mantenimiento'
            WHEN 4 THEN 'Personal de restauración'
            WHEN 5 THEN 'Agente comercial'
            ELSE 'Administrativo'
        END AS puesto
    FROM oltp_rrhh.empleado e
    WHERE e.id_empleado % 6 = 0
) x;

SELECT setval('oltp_rrhh.departamento_id_departamento_seq', (SELECT MAX(id_departamento) FROM oltp_rrhh.departamento), true);
SELECT setval('oltp_rrhh.empleado_id_empleado_seq', (SELECT MAX(id_empleado) FROM oltp_rrhh.empleado), true);
SELECT setval('oltp_rrhh.contrato_id_contrato_seq', (SELECT MAX(id_contrato) FROM oltp_rrhh.contrato), true);
SELECT setval('oltp_rrhh.turno_id_turno_seq', (SELECT MAX(id_turno) FROM oltp_rrhh.turno), true);
SELECT setval('oltp_rrhh.asignacion_hotel_id_asignacion_hotel_seq', (SELECT MAX(id_asignacion_hotel) FROM oltp_rrhh.asignacion_hotel), true);
