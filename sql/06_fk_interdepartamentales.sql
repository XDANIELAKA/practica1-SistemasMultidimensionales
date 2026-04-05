ALTER TABLE oltp_reservas.detalle_reserva
    ADD CONSTRAINT fk_detalle_reserva_hotel
    FOREIGN KEY (id_hotel)
    REFERENCES oltp_alojamientos.hotel(id_hotel);

ALTER TABLE oltp_reservas.detalle_reserva
    ADD CONSTRAINT fk_detalle_reserva_tarifa
    FOREIGN KEY (id_tarifa)
    REFERENCES oltp_alojamientos.tarifa(id_tarifa);

ALTER TABLE oltp_operaciones.consumo_servicio
    ADD CONSTRAINT fk_consumo_servicio_reserva
    FOREIGN KEY (id_reserva)
    REFERENCES oltp_reservas.reserva(id_reserva);

ALTER TABLE oltp_operaciones.consumo_servicio
    ADD CONSTRAINT fk_consumo_servicio_hotel
    FOREIGN KEY (id_hotel)
    REFERENCES oltp_alojamientos.hotel(id_hotel);

ALTER TABLE oltp_operaciones.incidencia
    ADD CONSTRAINT fk_incidencia_hotel
    FOREIGN KEY (id_hotel)
    REFERENCES oltp_alojamientos.hotel(id_hotel);

ALTER TABLE oltp_operaciones.incidencia
    ADD CONSTRAINT fk_incidencia_habitacion
    FOREIGN KEY (id_habitacion)
    REFERENCES oltp_alojamientos.habitacion(id_habitacion);

ALTER TABLE oltp_rrhh.asignacion_hotel
    ADD CONSTRAINT fk_asignacion_hotel_hotel
    FOREIGN KEY (id_hotel)
    REFERENCES oltp_alojamientos.hotel(id_hotel);

ALTER TABLE oltp_finanzas.centro_coste
    ADD CONSTRAINT fk_centro_coste_hotel
    FOREIGN KEY (id_hotel)
    REFERENCES oltp_alojamientos.hotel(id_hotel);

ALTER TABLE oltp_finanzas.factura
    ADD CONSTRAINT fk_factura_reserva
    FOREIGN KEY (id_reserva)
    REFERENCES oltp_reservas.reserva(id_reserva);

ALTER TABLE oltp_finanzas.coste_operativo
    ADD CONSTRAINT fk_coste_operativo_mantenimiento
    FOREIGN KEY (id_mantenimiento)
    REFERENCES oltp_operaciones.mantenimiento(id_mantenimiento);
