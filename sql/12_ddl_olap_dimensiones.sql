DROP SCHEMA IF EXISTS olap CASCADE;
CREATE SCHEMA olap;

CREATE TABLE olap.dim_tiempo (
    tiempo_sk SERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    trimestre INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(15) NOT NULL,
    dia INT NOT NULL,
    dia_semana INT NOT NULL,
    nombre_dia VARCHAR(15) NOT NULL,
    temporada VARCHAR(15) NOT NULL
);

CREATE TABLE olap.dim_hotel (
    hotel_sk SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL UNIQUE,
    nombre_hotel VARCHAR(120) NOT NULL,
    categoria SMALLINT NOT NULL,
    ciudad VARCHAR(80) NOT NULL,
    provincia VARCHAR(80) NOT NULL,
    comunidad_autonoma VARCHAR(80) NOT NULL,
    fecha_apertura DATE NOT NULL,
    activo BOOLEAN NOT NULL
);

CREATE TABLE olap.dim_cliente (
    cliente_sk SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    nombre_completo VARCHAR(201) NOT NULL,
    pais VARCHAR(60) NOT NULL,
    comunidad_autonoma VARCHAR(60),
    ciudad VARCHAR(80),
    tipo_cliente VARCHAR(20) NOT NULL,
    fecha_registro DATE NOT NULL
);

CREATE TABLE olap.dim_canal_reserva (
    canal_reserva_sk SERIAL PRIMARY KEY,
    canal_reserva_id INT NOT NULL UNIQUE,
    nombre_canal VARCHAR(80) NOT NULL,
    tipo_canal VARCHAR(30) NOT NULL,
    comision NUMERIC(5,2) NOT NULL,
    activo BOOLEAN NOT NULL
);

CREATE TABLE olap.dim_habitacion (
    habitacion_sk SERIAL PRIMARY KEY,
    habitacion_id INT NOT NULL UNIQUE,
    hotel_id INT NOT NULL,
    tipo_habitacion_id INT NOT NULL,
    numero_habitacion VARCHAR(10) NOT NULL,
    planta SMALLINT NOT NULL,
    vista VARCHAR(30) NOT NULL,
    estado_habitacion VARCHAR(20) NOT NULL,
    tipo_habitacion VARCHAR(60) NOT NULL,
    capacidad_maxima SMALLINT NOT NULL,
    metros_cuadrados NUMERIC(5,2) NOT NULL
);

CREATE TABLE olap.dim_tarifa (
    tarifa_sk SERIAL PRIMARY KEY,
    tarifa_id INT NOT NULL UNIQUE,
    hotel_id INT NOT NULL,
    tipo_habitacion_id INT NOT NULL,
    temporada_id INT NOT NULL,
    nombre_tarifa VARCHAR(60) NOT NULL,
    tipo_habitacion VARCHAR(60) NOT NULL,
    nombre_temporada VARCHAR(40) NOT NULL,
    tipo_pension VARCHAR(30) NOT NULL,
    paquete_contratado VARCHAR(60),
    precio_noche NUMERIC(10,2) NOT NULL,
    moneda CHAR(3) NOT NULL
);

CREATE TABLE olap.dim_servicio (
    servicio_sk SERIAL PRIMARY KEY,
    servicio_id INT NOT NULL UNIQUE,
    nombre_servicio VARCHAR(100) NOT NULL,
    categoria_servicio VARCHAR(40) NOT NULL,
    precio_base NUMERIC(10,2) NOT NULL,
    activo BOOLEAN NOT NULL
);

CREATE INDEX idx_dim_tiempo_fecha
    ON olap.dim_tiempo(fecha);

CREATE INDEX idx_dim_hotel_hotel_id
    ON olap.dim_hotel(hotel_id);

CREATE INDEX idx_dim_cliente_cliente_id
    ON olap.dim_cliente(cliente_id);

CREATE INDEX idx_dim_canal_reserva_canal_id
    ON olap.dim_canal_reserva(canal_reserva_id);

CREATE INDEX idx_dim_habitacion_habitacion_id
    ON olap.dim_habitacion(habitacion_id);

CREATE INDEX idx_dim_habitacion_hotel_tipo
    ON olap.dim_habitacion(hotel_id, tipo_habitacion_id);

CREATE INDEX idx_dim_tarifa_tarifa_id
    ON olap.dim_tarifa(tarifa_id);

CREATE INDEX idx_dim_tarifa_hotel_tipo
    ON olap.dim_tarifa(hotel_id, tipo_habitacion_id);

CREATE INDEX idx_dim_servicio_servicio_id
    ON olap.dim_servicio(servicio_id);
