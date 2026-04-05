DROP SCHEMA IF EXISTS olap_snow CASCADE;
CREATE SCHEMA olap_snow;

-- =========================
-- Dimensiones snowflake
-- =========================

CREATE TABLE olap_snow.dim_tiempo (
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

CREATE TABLE olap_snow.dim_cliente (
    cliente_sk SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    nombre_completo VARCHAR(200) NOT NULL,
    pais VARCHAR(60) NOT NULL,
    comunidad_autonoma VARCHAR(60),
    ciudad VARCHAR(80),
    tipo_cliente VARCHAR(40),
    fecha_registro DATE
);

CREATE TABLE olap_snow.dim_canal_reserva (
    canal_reserva_sk SERIAL PRIMARY KEY,
    canal_reserva_id INT NOT NULL UNIQUE,
    nombre_canal VARCHAR(80) NOT NULL,
    tipo_canal VARCHAR(40),
    comision NUMERIC(5,2)
);

CREATE TABLE olap_snow.dim_servicio (
    servicio_sk SERIAL PRIMARY KEY,
    servicio_id INT NOT NULL UNIQUE,
    nombre_servicio VARCHAR(100) NOT NULL,
    categoria_servicio VARCHAR(80),
    precio_base NUMERIC(10,2),
    activo BOOLEAN
);

CREATE TABLE olap_snow.dim_habitacion (
    habitacion_sk SERIAL PRIMARY KEY,
    habitacion_id INT NOT NULL UNIQUE,
    hotel_id INT NOT NULL,
    numero_habitacion VARCHAR(20) NOT NULL,
    planta INT,
    estado_habitacion VARCHAR(30),
    tipo_habitacion VARCHAR(80),
    capacidad_maxima INT
);

CREATE TABLE olap_snow.dim_tarifa (
    tarifa_sk SERIAL PRIMARY KEY,
    tarifa_id INT NOT NULL UNIQUE,
    hotel_id INT NOT NULL,
    tipo_habitacion VARCHAR(80),
    nombre_temporada VARCHAR(80),
    tipo_pension VARCHAR(40),
    paquete_contratado VARCHAR(120),
    precio_noche NUMERIC(10,2)
);

-- =========================
-- Snowflake de hotel
-- =========================

CREATE TABLE olap_snow.dim_geografia (
    geografia_sk SERIAL PRIMARY KEY,
    ciudad VARCHAR(80) NOT NULL,
    provincia VARCHAR(80) NOT NULL,
    comunidad_autonoma VARCHAR(80) NOT NULL,
    CONSTRAINT uq_dim_geografia UNIQUE (ciudad, provincia, comunidad_autonoma)
);

CREATE TABLE olap_snow.dim_hotel (
    hotel_sk SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL UNIQUE,
    nombre_hotel VARCHAR(120) NOT NULL,
    categoria INT,
    geografia_sk INT NOT NULL REFERENCES olap_snow.dim_geografia(geografia_sk)
);

-- =========================
-- Hechos snowflake
-- =========================

CREATE TABLE olap_snow.fact_reservas (
    reserva_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap_snow.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap_snow.dim_hotel(hotel_sk),
    cliente_sk INT NOT NULL REFERENCES olap_snow.dim_cliente(cliente_sk),
    canal_reserva_sk INT NOT NULL REFERENCES olap_snow.dim_canal_reserva(canal_reserva_sk),
    tarifa_sk INT NOT NULL REFERENCES olap_snow.dim_tarifa(tarifa_sk),
    reserva_id INT NOT NULL,
    noches_reservadas INT NOT NULL,
    importe_reserva NUMERIC(12,2) NOT NULL,
    cancelada BOOLEAN NOT NULL,
    total_pagado NUMERIC(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_snow_fact_reservas UNIQUE (reserva_id)
);

CREATE TABLE olap_snow.fact_estancias (
    estancia_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap_snow.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap_snow.dim_hotel(hotel_sk),
    habitacion_sk INT NOT NULL REFERENCES olap_snow.dim_habitacion(habitacion_sk),
    cliente_sk INT NOT NULL REFERENCES olap_snow.dim_cliente(cliente_sk),
    tarifa_sk INT NOT NULL REFERENCES olap_snow.dim_tarifa(tarifa_sk),
    detalle_reserva_id INT NOT NULL,
    noches_ocupadas INT NOT NULL,
    ingreso_alojamiento NUMERIC(12,2) NOT NULL,
    CONSTRAINT uq_snow_fact_estancias UNIQUE (detalle_reserva_id)
);

CREATE TABLE olap_snow.fact_servicios (
    servicio_fact_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap_snow.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap_snow.dim_hotel(hotel_sk),
    cliente_sk INT NOT NULL REFERENCES olap_snow.dim_cliente(cliente_sk),
    servicio_sk INT NOT NULL REFERENCES olap_snow.dim_servicio(servicio_sk),
    consumo_servicio_id INT NOT NULL,
    cantidad INT NOT NULL,
    importe_servicio NUMERIC(12,2) NOT NULL,
    CONSTRAINT uq_snow_fact_servicios UNIQUE (consumo_servicio_id)
);

CREATE INDEX idx_snow_fact_reservas_tiempo ON olap_snow.fact_reservas(tiempo_sk);
CREATE INDEX idx_snow_fact_reservas_hotel ON olap_snow.fact_reservas(hotel_sk);
CREATE INDEX idx_snow_fact_estancias_tiempo ON olap_snow.fact_estancias(tiempo_sk);
CREATE INDEX idx_snow_fact_estancias_hotel ON olap_snow.fact_estancias(hotel_sk);
CREATE INDEX idx_snow_fact_servicios_tiempo ON olap_snow.fact_servicios(tiempo_sk);
CREATE INDEX idx_snow_fact_servicios_hotel ON olap_snow.fact_servicios(hotel_sk);
