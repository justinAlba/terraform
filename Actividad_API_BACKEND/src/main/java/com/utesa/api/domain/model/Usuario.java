package com.utesa.api.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Usuario {

    private Long id;
    private String nombre;
    private String email;
    private String password;
    private Rol rol;
    private Instant fechaCreacion;
}
