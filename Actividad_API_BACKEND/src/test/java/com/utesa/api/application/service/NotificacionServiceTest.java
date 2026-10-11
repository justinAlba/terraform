package com.utesa.api.application.service;

import com.utesa.api.domain.model.Notificacion;
import com.utesa.api.domain.port.out.NotificacionPublisherPort;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class NotificacionServiceTest {

    @Test
    void publicaLaNotificacionNormalizadaYDevuelveElMessageId() {
        NotificacionPublisherPort publisher = mock(NotificacionPublisherPort.class);
        when(publisher.publicar(any())).thenReturn("msg-123");
        NotificacionService service = new NotificacionService(publisher);

        String messageId = service.enviar(new Notificacion(
                "  usuario@correo.com ", " Prueba SNS ", "Hola desde AWS Serverless", "admin@correo.com"));

        assertThat(messageId).isEqualTo("msg-123");
        ArgumentCaptor<Notificacion> captor = ArgumentCaptor.forClass(Notificacion.class);
        verify(publisher).publicar(captor.capture());
        assertThat(captor.getValue()).isEqualTo(new Notificacion(
                "usuario@correo.com", "Prueba SNS", "Hola desde AWS Serverless", "admin@correo.com"));
    }
}
