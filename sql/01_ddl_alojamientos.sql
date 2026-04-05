CREATE TABLE oltp_alojamientos.hotel (
    id_hotel SERIAL PRIMARY KEY,
    nombre_hotel VARCHAR(120) NOT NULL UNIQUE,
    categoria SMALLINT NOT NULL,
    ciudad VARCHAR(80) NOT NULL,
    provincia VARCHAR(80) NOT NULL,
    comunidad_autonoma VARCHAR(80) NOT NULL,
    fecha_apertura DATE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_hotel_categoria CHECK (categoria BETWEEN 3 AND 5)
);

CREATE TABLE oltp_alojamientos.tipo_habitacion (
    id_tipo_habitacion SERIAL PRIMARY KEY,
    nombre_tipo VARCHAR(60) NOT NULL UNIQUE,
    capacidad_maxima SMALLINT NOT NULL,
    metros_cuadrados NUMERIC(5,2) NOT NULL,
    descripcion VARCHAR(200),
    CONSTRAINT chk_tipo_habitacion_capacidad CHECK (capacidad_maxima BETWEEN 1 AND 8),
    CONSTRAINT chk_tipo_habitacion_metros CHECK (metros_cuadrados > 0)
);

CREATE TABLE oltp_alojamientos.temporada (
    id_temporada SERIAL PRIMARY KEY,
    nombre_temporada VARCHAR(40) NOT NULL UNIQUE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CONSTRAINT chk_temporada_fechas CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE oltp_alojamientos.habitacion (
    id_habitacion SERIAL PRIMARY KEY,
    id_hotel INT NOT NULL,
    id_tipo_habitacion INT NOT NULL,
    numero_habitacion VARCHAR(10) NOT NULL,
    planta SMALLINT NOT NULL,
    vista VARCHAR(30) NOT NULL,
    estado_habitacion VARCHAR(20) NOT NULL DEFAULT 'disponible',
    CONSTRAINT fk_habitacion_hotel
        FOREIGN KEY (id_hotel)
        REFERENCES oltp_alojamientos.hotel(id_hotel),
    CONSTRAINT fk_habitacion_tipo
        FOREIGN KEY (id_tipo_habitacion)
        REFERENCES oltp_alojamientos.tipo_habitacion(id_tipo_habitacion),
    CONSTRAINT uq_habitacion_hotel_numero UNIQUE (id_hotel, numero_habitacion),
    CONSTRAINT chk_habitacion_planta CHECK (planta >= 0),
    CONSTRAINT chk_habitacion_vista CHECK (vista IN ('mar', 'piscina', 'jardin', 'ciudad', 'montana')),
    CONSTRAINT chk_habitacion_estado CHECK (estado_habitacion IN ('disponible', 'ocupada', 'mantenimiento', 'bloqueada'))
);

CREATE TABLE oltp_alojamientos.tarifa (
    id_tarifa SERIAL PRIMARY KEY,
    id_hotel INT NOT NULL,
    id_tipo_habitacion INT NOT NULL,
    id_temporada INT NOT NULL,
    nombre_tarifa VARCHAR(60) NOT NULL,
    tipo_pension VARCHAR(30) NOT NULL,
    paquete_contratado VARCHAR(60),
    precio_noche NUMERIC(10,2) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'EUR',
    CONSTRAINT fk_tarifa_hotel
        FOREIGN KEY (id_hotel)
        REFERENCES oltp_alojamientos.hotel(id_hotel),
    CONSTRAINT fk_tarifa_tipo
        FOREIGN KEY (id_tipo_habitacion)
        REFERENCES oltp_alojamientos.tipo_habitacion(id_tipo_habitacion),
    CONSTRAINT fk_tarifa_temporada
        FOREIGN KEY (id_temporada)
        REFERENCES oltp_alojamientos.temporada(id_temporada),
    CONSTRAINT uq_tarifa_contexto UNIQUE (id_hotel, id_tipo_habitacion, id_temporada, nombre_tarifa),
    CONSTRAINT chk_tarifa_pension CHECK (tipo_pension IN ('solo_alojamiento', 'desayuno', 'media_pension', 'pension_completa', 'todo_incluido')),
    CONSTRAINT chk_tarifa_precio CHECK (precio_noche > 0),
    CONSTRAINT chk_tarifa_moneda CHECK (moneda = 'EUR')
);

CREATE INDEX idx_habitacion_hotel
    ON oltp_alojamientos.habitacion(id_hotel);

CREATE INDEX idx_habitacion_tipo
    ON oltp_alojamientos.habitacion(id_tipo_habitacion);

CREATE INDEX idx_tarifa_hotel
    ON oltp_alojamientos.tarifa(id_hotel);

CREATE INDEX idx_tarifa_tipo
    ON oltp_alojamientos.tarifa(id_tipo_habitacion);

CREATE INDEX idx_tarifa_temporada
    ON oltp_alojamientos.tarifa(id_temporada);

CREATE INDEX idx_hotel_ubicacion
    ON oltp_alojamientos.hotel(provincia, ciudad);
