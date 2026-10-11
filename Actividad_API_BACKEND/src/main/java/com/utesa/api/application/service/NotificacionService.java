package com.utesa.api.application.service;

import com.utesa.api.domain.model.Notificacion;
import com.utesa.api.domain.port.in.NotificacionUseCase;
import com.utesa.api.domain.port.out.NotificacionPublisherPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificacionService implements NotificacionUseCase {

    private final NotificacionPublisherPort notificacionPublisherPort;

    @Override
    public String enviar(Notificacion notificacion) {
        Notificacion normalizada = new Notificacion(
                notificacion.email().trim(),
                notificacion.asunto().trim(),
                notificacion.mensaje(),
                notificacion.solicitadoPor());
        return notificacionPublisherPort.publicar(normalizada);
    }
}
