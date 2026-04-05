DROP TABLE IF EXISTS olap.fact_servicios CASCADE;
DROP TABLE IF EXISTS olap.fact_estancias CASCADE;
DROP TABLE IF EXISTS olap.fact_reservas CASCADE;

CREATE TABLE olap.fact_reservas (
    reserva_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap.dim_hotel(hotel_sk),
    cliente_sk INT NOT NULL REFERENCES olap.dim_cliente(cliente_sk),
    canal_reserva_sk INT NOT NULL REFERENCES olap.dim_canal_reserva(canal_reserva_sk),
    tarifa_sk INT NOT NULL REFERENCES olap.dim_tarifa(tarifa_sk),
    reserva_id INT NOT NULL,
    noches_reservadas INT NOT NULL,
    importe_reserva NUMERIC(12,2) NOT NULL,
    cancelada BOOLEAN NOT NULL,
    total_pagado NUMERIC(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_fact_reservas_reserva UNIQUE (reserva_id),
    CONSTRAINT chk_fact_reservas_noches CHECK (noches_reservadas >= 0),
    CONSTRAINT chk_fact_reservas_importe CHECK (importe_reserva >= 0),
    CONSTRAINT chk_fact_reservas_pagado CHECK (total_pagado >= 0)
);

CREATE TABLE olap.fact_estancias (
    estancia_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap.dim_hotel(hotel_sk),
    habitacion_sk INT NOT NULL REFERENCES olap.dim_habitacion(habitacion_sk),
    cliente_sk INT NOT NULL REFERENCES olap.dim_cliente(cliente_sk),
    tarifa_sk INT NOT NULL REFERENCES olap.dim_tarifa(tarifa_sk),
    detalle_reserva_id INT NOT NULL,
    noches_ocupadas INT NOT NULL,
    ingreso_alojamiento NUMERIC(12,2) NOT NULL,
    CONSTRAINT uq_fact_estancias_detalle UNIQUE (detalle_reserva_id),
    CONSTRAINT chk_fact_estancias_noches CHECK (noches_ocupadas >= 0),
    CONSTRAINT chk_fact_estancias_ingreso CHECK (ingreso_alojamiento >= 0)
);

CREATE TABLE olap.fact_servicios (
    servicio_fact_sk SERIAL PRIMARY KEY,
    tiempo_sk INT NOT NULL REFERENCES olap.dim_tiempo(tiempo_sk),
    hotel_sk INT NOT NULL REFERENCES olap.dim_hotel(hotel_sk),
    cliente_sk INT NOT NULL REFERENCES olap.dim_cliente(cliente_sk),
    servicio_sk INT NOT NULL REFERENCES olap.dim_servicio(servicio_sk),
    consumo_servicio_id INT NOT NULL,
    cantidad INT NOT NULL,
    importe_servicio NUMERIC(12,2) NOT NULL,
    CONSTRAINT uq_fact_servicios_consumo UNIQUE (consumo_servicio_id),
    CONSTRAINT chk_fact_servicios_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_fact_servicios_importe CHECK (importe_servicio >= 0)
);

CREATE INDEX idx_fact_reservas_tiempo ON olap.fact_reservas(tiempo_sk);
CREATE INDEX idx_fact_reservas_hotel ON olap.fact_reservas(hotel_sk);
CREATE INDEX idx_fact_reservas_cliente ON olap.fact_reservas(cliente_sk);
CREATE INDEX idx_fact_reservas_canal ON olap.fact_reservas(canal_reserva_sk);
CREATE INDEX idx_fact_reservas_tarifa ON olap.fact_reservas(tarifa_sk);

CREATE INDEX idx_fact_estancias_tiempo ON olap.fact_estancias(tiempo_sk);
CREATE INDEX idx_fact_estancias_hotel ON olap.fact_estancias(hotel_sk);
CREATE INDEX idx_fact_estancias_habitacion ON olap.fact_estancias(habitacion_sk);
CREATE INDEX idx_fact_estancias_cliente ON olap.fact_estancias(cliente_sk);
CREATE INDEX idx_fact_estancias_tarifa ON olap.fact_estancias(tarifa_sk);

CREATE INDEX idx_fact_servicios_tiempo ON olap.fact_servicios(tiempo_sk);
CREATE INDEX idx_fact_servicios_hotel ON olap.fact_servicios(hotel_sk);
CREATE INDEX idx_fact_servicios_cliente ON olap.fact_servicios(cliente_sk);
CREATE INDEX idx_fact_servicios_servicio ON olap.fact_servicios(servicio_sk);
