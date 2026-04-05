CREATE TABLE oltp_operaciones.servicio (
    id_servicio SERIAL PRIMARY KEY,
    nombre_servicio VARCHAR(100) NOT NULL UNIQUE,
    categoria_servicio VARCHAR(40) NOT NULL,
    precio_base NUMERIC(10,2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_servicio_categoria CHECK (categoria_servicio IN ('restauracion', 'spa', 'evento', 'ocio', 'transporte')),
    CONSTRAINT chk_servicio_precio CHECK (precio_base >= 0)
);

CREATE TABLE oltp_operaciones.proveedor_servicio (
    id_proveedor_servicio SERIAL PRIMARY KEY,
    nombre_proveedor VARCHAR(120) NOT NULL UNIQUE,
    nif VARCHAR(15) NOT NULL UNIQUE,
    tipo_servicio VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(120) UNIQUE,
    ciudad VARCHAR(80) NOT NULL
);

CREATE TABLE oltp_operaciones.incidencia (
    id_incidencia SERIAL PRIMARY KEY,
    id_hotel INT NOT NULL,
    id_habitacion INT,
    tipo_incidencia VARCHAR(40) NOT NULL,
    descripcion VARCHAR(250) NOT NULL,
    fecha_apertura DATE NOT NULL,
    fecha_cierre DATE,
    prioridad VARCHAR(20) NOT NULL,
    estado_incidencia VARCHAR(20) NOT NULL,
    CONSTRAINT chk_incidencia_tipo CHECK (tipo_incidencia IN ('mantenimiento', 'limpieza', 'electricidad', 'fontaneria', 'climatizacion', 'otro')),
    CONSTRAINT chk_incidencia_prioridad CHECK (prioridad IN ('baja', 'media', 'alta', 'critica')),
    CONSTRAINT chk_incidencia_estado CHECK (estado_incidencia IN ('abierta', 'en_proceso', 'resuelta', 'cerrada')),
    CONSTRAINT chk_incidencia_fechas CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura)
);

CREATE TABLE oltp_operaciones.mantenimiento (
    id_mantenimiento SERIAL PRIMARY KEY,
    id_incidencia INT NOT NULL,
    id_proveedor_servicio INT NOT NULL,
    fecha_mantenimiento DATE NOT NULL,
    coste_mantenimiento NUMERIC(10,2) NOT NULL,
    resultado VARCHAR(120) NOT NULL,
    estado_mantenimiento VARCHAR(20) NOT NULL,
    CONSTRAINT fk_mantenimiento_incidencia
        FOREIGN KEY (id_incidencia)
        REFERENCES oltp_operaciones.incidencia(id_incidencia),
    CONSTRAINT fk_mantenimiento_proveedor
        FOREIGN KEY (id_proveedor_servicio)
        REFERENCES oltp_operaciones.proveedor_servicio(id_proveedor_servicio),
    CONSTRAINT chk_mantenimiento_coste CHECK (coste_mantenimiento >= 0),
    CONSTRAINT chk_mantenimiento_estado CHECK (estado_mantenimiento IN ('programado', 'realizado', 'cancelado'))
);

CREATE TABLE oltp_operaciones.consumo_servicio (
    id_consumo_servicio SERIAL PRIMARY KEY,
    id_servicio INT NOT NULL,
    id_reserva INT NOT NULL,
    id_hotel INT NOT NULL,
    fecha_consumo DATE NOT NULL,
    cantidad INT NOT NULL,
    importe_total NUMERIC(10,2) NOT NULL,
    observaciones VARCHAR(200),
    CONSTRAINT fk_consumo_servicio_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES oltp_operaciones.servicio(id_servicio),
    CONSTRAINT chk_consumo_servicio_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_consumo_servicio_importe CHECK (importe_total >= 0)
);

CREATE INDEX idx_incidencia_hotel
    ON oltp_operaciones.incidencia(id_hotel);

CREATE INDEX idx_incidencia_habitacion
    ON oltp_operaciones.incidencia(id_habitacion);

CREATE INDEX idx_incidencia_fecha
    ON oltp_operaciones.incidencia(fecha_apertura);

CREATE INDEX idx_mantenimiento_incidencia
    ON oltp_operaciones.mantenimiento(id_incidencia);

CREATE INDEX idx_mantenimiento_proveedor
    ON oltp_operaciones.mantenimiento(id_proveedor_servicio);

CREATE INDEX idx_consumo_servicio_reserva
    ON oltp_operaciones.consumo_servicio(id_reserva);

CREATE INDEX idx_consumo_servicio_servicio
    ON oltp_operaciones.consumo_servicio(id_servicio);

CREATE INDEX idx_consumo_servicio_hotel
    ON oltp_operaciones.consumo_servicio(id_hotel);
