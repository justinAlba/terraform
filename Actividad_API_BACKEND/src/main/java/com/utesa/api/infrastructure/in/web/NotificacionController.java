package com.utesa.api.infrastructure.in.web;

import com.utesa.api.domain.model.Notificacion;
import com.utesa.api.domain.port.in.NotificacionUseCase;
import com.utesa.api.infrastructure.in.web.dto.NotificacionRequest;
import com.utesa.api.infrastructure.in.web.dto.NotificacionResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

/**
 * Requiere JWT como el resto de la API: un endpoint abierto que envia correos
 * a cualquier direccion seria un relay de spam.
 */
@RestController
@RequestMapping({"/api/notifications", "/notifications"})
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionUseCase notificacionUseCase;

    @PostMapping("/send")
    public ResponseEntity<NotificacionResponse> enviar(@Valid @RequestBody NotificacionRequest request,
                                                       Principal principal) {
        Notificacion notificacion = new Notificacion(
                request.email(),
                request.subject(),
                request.message(),
                principal.getName());
        String messageId = notificacionUseCase.enviar(notificacion);
        // 202: el correo se envia de forma asincrona (SNS -> SQS -> Lambda).
        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(new NotificacionResponse(messageId, "Mensaje enviado correctamente."));
    }
}
