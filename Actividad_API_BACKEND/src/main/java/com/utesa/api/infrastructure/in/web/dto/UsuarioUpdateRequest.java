package com.utesa.api.infrastructure.in.web.dto;

import com.utesa.api.domain.model.Rol;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UsuarioUpdateRequest(
        @NotBlank(message = "El nombre es obligatorio")
        String nombre,

        @NotBlank(message = "El email es obligatorio")
        @Email(message = "El email no tiene un formato valido")
        String email,

        String password,

        @NotNull(message = "El rol es obligatorio")
        Rol rol
) {
}
