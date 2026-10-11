package com.utesa.api.domain.model;

/**
 * Correo que la app movil pide enviar. Viaja por SNS -> SQS hasta la Lambda de notificaciones.
 */
public record Notificacion(
        String email,
        String asunto,
        String mensaje,
        String solicitadoPor
) {
}
