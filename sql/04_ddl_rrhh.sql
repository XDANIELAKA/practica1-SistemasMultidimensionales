CREATE TABLE oltp_rrhh.departamento (
    id_departamento SERIAL PRIMARY KEY,
    nombre_departamento VARCHAR(80) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
);

CREATE TABLE oltp_rrhh.empleado (
    id_empleado SERIAL PRIMARY KEY,
    id_departamento INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    dni VARCHAR(12) NOT NULL UNIQUE,
    telefono VARCHAR(20) UNIQUE,
    email VARCHAR(120) UNIQUE,
    fecha_alta DATE NOT NULL,
    estado_empleado VARCHAR(20) NOT NULL DEFAULT 'activo',
    CONSTRAINT fk_empleado_departamento
        FOREIGN KEY (id_departamento)
        REFERENCES oltp_rrhh.departamento(id_departamento),
    CONSTRAINT chk_empleado_estado CHECK (estado_empleado IN ('activo', 'baja', 'excedencia'))
);

CREATE TABLE oltp_rrhh.contrato (
    id_contrato SERIAL PRIMARY KEY,
    id_empleado INT NOT NULL,
    tipo_contrato VARCHAR(30) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    salario_base NUMERIC(10,2) NOT NULL,
    jornada VARCHAR(20) NOT NULL,
    CONSTRAINT fk_contrato_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES oltp_rrhh.empleado(id_empleado),
    CONSTRAINT chk_contrato_tipo CHECK (tipo_contrato IN ('indefinido', 'temporal', 'fijo_discontinuo', 'practicas')),
    CONSTRAINT chk_contrato_salario CHECK (salario_base > 0),
    CONSTRAINT chk_contrato_jornada CHECK (jornada IN ('completa', 'parcial')),
    CONSTRAINT chk_contrato_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);

CREATE TABLE oltp_rrhh.turno (
    id_turno SERIAL PRIMARY KEY,
    id_empleado INT NOT NULL,
    fecha_turno DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    tipo_turno VARCHAR(20) NOT NULL,
    CONSTRAINT fk_turno_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES oltp_rrhh.empleado(id_empleado),
    CONSTRAINT chk_turno_tipo CHECK (tipo_turno IN ('manana', 'tarde', 'noche'))
);

CREATE TABLE oltp_rrhh.asignacion_hotel (
    id_asignacion_hotel SERIAL PRIMARY KEY,
    id_empleado INT NOT NULL,
    id_hotel INT NOT NULL,
    fecha_inicio_asignacion DATE NOT NULL,
    fecha_fin_asignacion DATE,
    puesto VARCHAR(60) NOT NULL,
    CONSTRAINT fk_asignacion_hotel_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES oltp_rrhh.empleado(id_empleado),
    CONSTRAINT chk_asignacion_hotel_fechas CHECK (fecha_fin_asignacion IS NULL OR fecha_fin_asignacion >= fecha_inicio_asignacion)
);

CREATE INDEX idx_empleado_departamento
    ON oltp_rrhh.empleado(id_departamento);

CREATE INDEX idx_contrato_empleado
    ON oltp_rrhh.contrato(id_empleado);

CREATE INDEX idx_turno_empleado
    ON oltp_rrhh.turno(id_empleado);

CREATE INDEX idx_turno_fecha
    ON oltp_rrhh.turno(fecha_turno);

CREATE INDEX idx_asignacion_hotel_empleado
    ON oltp_rrhh.asignacion_hotel(id_empleado);

CREATE INDEX idx_asignacion_hotel_hotel
    ON oltp_rrhh.asignacion_hotel(id_hotel);
