package com.utesa.api.domain.port.in;

import com.utesa.api.domain.model.Notificacion;

public interface NotificacionUseCase {

    /**
     * Encola la notificacion y devuelve el id del mensaje publicado.
     */
    String enviar(Notificacion notificacion);
}
