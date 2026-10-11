package com.utesa.api.infrastructure.out.messaging;

import com.utesa.api.domain.model.Notificacion;
import com.utesa.api.domain.port.out.NotificacionPublisherPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Ejecucion local y Docker: no hay SNS, solo se registra la notificacion en el log.
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.notifications.provider", havingValue = "log", matchIfMissing = true)
public class LogNotificacionAdapter implements NotificacionPublisherPort {

    @Override
    public String publicar(Notificacion notificacion) {
        String messageId = "local-" + UUID.randomUUID();
        log.info("[LOCAL] Notificacion para {} asunto='{}' messageId={} (no se envia correo)",
                notificacion.email(), notificacion.asunto(), messageId);
        return messageId;
    }
}
