package com.utesa.api.infrastructure.in.web.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "El email es obligatorio")
        String email,

        @NotBlank(message = "La contrasena es obligatoria")
        String password
) {
}
