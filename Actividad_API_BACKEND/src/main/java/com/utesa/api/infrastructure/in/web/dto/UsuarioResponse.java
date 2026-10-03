package com.utesa.api.infrastructure.in.web.dto;

import com.utesa.api.domain.model.Rol;
import com.utesa.api.domain.model.Usuario;

import java.time.Instant;

public record UsuarioResponse(
        Long id,
        String nombre,
        String email,
        Rol rol,
        Instant fechaCreacion
) {
    public static UsuarioResponse desde(Usuario usuario) {
        return new UsuarioResponse(
                usuario.getId(),
                usuario.getNombre(),
                usuario.getEmail(),
                usuario.getRol(),
                usuario.getFechaCreacion()
        );
    }
}
