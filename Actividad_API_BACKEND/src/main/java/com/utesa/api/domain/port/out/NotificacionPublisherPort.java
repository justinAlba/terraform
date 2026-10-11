package com.utesa.api.domain.port.out;

import com.utesa.api.domain.model.Notificacion;

public interface NotificacionPublisherPort {

    /**
     * Publica la notificacion y devuelve el id del mensaje.
     */
    String publicar(Notificacion notificacion);
}
