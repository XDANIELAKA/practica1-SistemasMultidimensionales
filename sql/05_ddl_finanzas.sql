CREATE TABLE oltp_finanzas.centro_coste (
    id_centro_coste SERIAL PRIMARY KEY,
    id_hotel INT NOT NULL,
    codigo_centro VARCHAR(20) NOT NULL UNIQUE,
    nombre_centro VARCHAR(100) NOT NULL,
    categoria_centro VARCHAR(40) NOT NULL,
    CONSTRAINT chk_centro_coste_categoria CHECK (categoria_centro IN ('alojamiento', 'restauracion', 'mantenimiento', 'rrhh', 'comercial', 'administracion'))
);

CREATE TABLE oltp_finanzas.factura (
    id_factura SERIAL PRIMARY KEY,
    id_centro_coste INT NOT NULL,
    id_reserva INT,
    numero_factura VARCHAR(30) NOT NULL UNIQUE,
    fecha_factura DATE NOT NULL,
    importe_total NUMERIC(10,2) NOT NULL,
    estado_factura VARCHAR(20) NOT NULL,
    CONSTRAINT fk_factura_centro_coste
        FOREIGN KEY (id_centro_coste)
        REFERENCES oltp_finanzas.centro_coste(id_centro_coste),
    CONSTRAINT chk_factura_importe CHECK (importe_total >= 0),
    CONSTRAINT chk_factura_estado CHECK (estado_factura IN ('emitida', 'pagada', 'anulada', 'pendiente'))
);

CREATE TABLE oltp_finanzas.linea_factura (
    id_linea_factura SERIAL PRIMARY KEY,
    id_factura INT NOT NULL,
    concepto VARCHAR(150) NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_linea_factura_factura
        FOREIGN KEY (id_factura)
        REFERENCES oltp_finanzas.factura(id_factura),
    CONSTRAINT chk_linea_factura_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_linea_factura_precio CHECK (precio_unitario >= 0),
    CONSTRAINT chk_linea_factura_subtotal CHECK (subtotal >= 0)
);

CREATE TABLE oltp_finanzas.coste_operativo (
    id_coste_operativo SERIAL PRIMARY KEY,
    id_centro_coste INT NOT NULL,
    id_mantenimiento INT,
    fecha_coste DATE NOT NULL,
    tipo_coste VARCHAR(40) NOT NULL,
    importe NUMERIC(10,2) NOT NULL,
    descripcion VARCHAR(200),
    CONSTRAINT fk_coste_operativo_centro
        FOREIGN KEY (id_centro_coste)
        REFERENCES oltp_finanzas.centro_coste(id_centro_coste),
    CONSTRAINT chk_coste_operativo_tipo CHECK (tipo_coste IN ('suministro', 'mantenimiento', 'personal', 'marketing', 'limpieza', 'otro')),
    CONSTRAINT chk_coste_operativo_importe CHECK (importe >= 0)
);

CREATE TABLE oltp_finanzas.presupuesto (
    id_presupuesto SERIAL PRIMARY KEY,
    id_centro_coste INT NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    importe_presupuestado NUMERIC(12,2) NOT NULL,
    observaciones VARCHAR(200),
    CONSTRAINT fk_presupuesto_centro
        FOREIGN KEY (id_centro_coste)
        REFERENCES oltp_finanzas.centro_coste(id_centro_coste),
    CONSTRAINT uq_presupuesto_periodo UNIQUE (id_centro_coste, periodo_inicio, periodo_fin),
    CONSTRAINT chk_presupuesto_importe CHECK (importe_presupuestado >= 0),
    CONSTRAINT chk_presupuesto_fechas CHECK (periodo_fin > periodo_inicio)
);

CREATE INDEX idx_factura_centro_coste
    ON oltp_finanzas.factura(id_centro_coste);

CREATE INDEX idx_factura_reserva
    ON oltp_finanzas.factura(id_reserva);

CREATE INDEX idx_factura_fecha
    ON oltp_finanzas.factura(fecha_factura);

CREATE INDEX idx_linea_factura_factura
    ON oltp_finanzas.linea_factura(id_factura);

CREATE INDEX idx_coste_operativo_centro
    ON oltp_finanzas.coste_operativo(id_centro_coste);

CREATE INDEX idx_coste_operativo_mantenimiento
    ON oltp_finanzas.coste_operativo(id_mantenimiento);

CREATE INDEX idx_presupuesto_centro
    ON oltp_finanzas.presupuesto(id_centro_coste);
