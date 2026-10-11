package com.utesa.api.infrastructure.out.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.utesa.api.domain.model.Notificacion;
import com.utesa.api.domain.port.out.NotificacionPublisherPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Publica en el topic SNS (despliegue en Lambda). SNS lo entrega a la cola SQS
 * y de ahi lo consume la Lambda de notificaciones, que envia el correo.
 * La region y las credenciales salen del entorno de Lambda (rol IAM creado por Terraform).
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.notifications.provider", havingValue = "sns")
public class SnsNotificacionAdapter implements NotificacionPublisherPort {

    private final SnsClient sns;
    private final String topicArn;
    private final ObjectMapper objectMapper;

    public SnsNotificacionAdapter(@Value("${app.notifications.sns-topic-arn}") String topicArn,
                                  ObjectMapper objectMapper) {
        this.sns = SnsClient.builder()
                .httpClient(UrlConnectionHttpClient.create())
                .build();
        this.topicArn = topicArn;
        this.objectMapper = objectMapper;
    }

    @Override
    public String publicar(Notificacion notificacion) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("email", notificacion.email());
        payload.put("subject", notificacion.asunto());
        payload.put("message", notificacion.mensaje());
        payload.put("requestedBy", notificacion.solicitadoPor());
        payload.put("requestedAt", Instant.now().toString());

        String cuerpo;
        try {
            cuerpo = objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("No se pudo serializar la notificacion", ex);
        }

        String messageId = sns.publish(PublishRequest.builder()
                        .topicArn(topicArn)
                        .subject("notificacion-email")
                        .message(cuerpo)
                        .build())
                .messageId();

        log.info("Notificacion publicada en SNS messageId={} solicitadoPor={}", messageId, notificacion.solicitadoPor());
        return messageId;
    }
}
