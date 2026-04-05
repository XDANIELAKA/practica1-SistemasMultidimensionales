CREATE TABLE oltp_reservas.cliente (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    telefono VARCHAR(20) UNIQUE,
    pais VARCHAR(60) NOT NULL,
    comunidad_autonoma VARCHAR(60),
    ciudad VARCHAR(80),
    tipo_cliente VARCHAR(20) NOT NULL DEFAULT 'estandar',
    fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_cliente_tipo CHECK (tipo_cliente IN ('estandar', 'premium', 'corporativo'))
);

CREATE TABLE oltp_reservas.canal_reserva (
    id_canal_reserva SERIAL PRIMARY KEY,
    nombre_canal VARCHAR(80) NOT NULL UNIQUE,
    tipo_canal VARCHAR(30) NOT NULL,
    comision NUMERIC(5,2) NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_canal_reserva_tipo CHECK (tipo_canal IN ('directo', 'ota', 'agencia', 'telefonico', 'corporativo')),
    CONSTRAINT chk_canal_reserva_comision CHECK (comision >= 0 AND comision <= 100)
);

CREATE TABLE oltp_reservas.reserva (
    id_reserva SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_canal_reserva INT NOT NULL,
    codigo_reserva VARCHAR(20) NOT NULL UNIQUE,
    fecha_reserva DATE NOT NULL,
    estado_reserva VARCHAR(20) NOT NULL,
    observaciones VARCHAR(250),
    CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES oltp_reservas.cliente(id_cliente),
    CONSTRAINT fk_reserva_canal
        FOREIGN KEY (id_canal_reserva)
        REFERENCES oltp_reservas.canal_reserva(id_canal_reserva),
    CONSTRAINT chk_reserva_estado CHECK (estado_reserva IN ('pendiente', 'confirmada', 'cancelada', 'completada'))
);

CREATE TABLE oltp_reservas.detalle_reserva (
    id_detalle_reserva SERIAL PRIMARY KEY,
    id_reserva INT NOT NULL UNIQUE,
    id_hotel INT NOT NULL,
    id_tarifa INT NOT NULL,
    fecha_entrada DATE NOT NULL,
    fecha_salida DATE NOT NULL,
    numero_huespedes SMALLINT NOT NULL,
    noches_reservadas SMALLINT NOT NULL,
    importe_previsto NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_detalle_reserva_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES oltp_reservas.reserva(id_reserva),
    CONSTRAINT chk_detalle_reserva_huespedes CHECK (numero_huespedes BETWEEN 1 AND 8),
    CONSTRAINT chk_detalle_reserva_noches CHECK (noches_reservadas > 0),
    CONSTRAINT chk_detalle_reserva_importe CHECK (importe_previsto >= 0),
    CONSTRAINT chk_detalle_reserva_fechas CHECK (fecha_salida > fecha_entrada)
);

CREATE TABLE oltp_reservas.pago_reserva (
    id_pago_reserva SERIAL PRIMARY KEY,
    id_reserva INT NOT NULL,
    fecha_pago DATE NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    importe_pagado NUMERIC(10,2) NOT NULL,
    estado_pago VARCHAR(20) NOT NULL,
    referencia_pago VARCHAR(40) NOT NULL UNIQUE,
    CONSTRAINT fk_pago_reserva_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES oltp_reservas.reserva(id_reserva),
    CONSTRAINT chk_pago_reserva_importe CHECK (importe_pagado > 0),
    CONSTRAINT chk_pago_reserva_metodo CHECK (metodo_pago IN ('tarjeta', 'transferencia', 'efectivo', 'bizum')),
    CONSTRAINT chk_pago_reserva_estado CHECK (estado_pago IN ('pendiente', 'pagado', 'reembolsado', 'fallido'))
);

CREATE INDEX idx_reserva_cliente
    ON oltp_reservas.reserva(id_cliente);

CREATE INDEX idx_reserva_canal
    ON oltp_reservas.reserva(id_canal_reserva);

CREATE INDEX idx_reserva_fecha
    ON oltp_reservas.reserva(fecha_reserva);

CREATE INDEX idx_detalle_reserva_hotel
    ON oltp_reservas.detalle_reserva(id_hotel);

CREATE INDEX idx_detalle_reserva_tarifa
    ON oltp_reservas.detalle_reserva(id_tarifa);

CREATE INDEX idx_pago_reserva_reserva
    ON oltp_reservas.pago_reserva(id_reserva);

CREATE INDEX idx_pago_reserva_fecha
    ON oltp_reservas.pago_reserva(fecha_pago);
