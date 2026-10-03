package com.utesa.api.infrastructure.config;

import com.utesa.api.domain.model.Rol;
import com.utesa.api.domain.model.Usuario;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private static final String SECRET = "clave-de-prueba-de-al-menos-32-caracteres-para-hs256";

    private final Usuario usuario = Usuario.builder()
            .id(7L)
            .nombre("Ana")
            .email("ana@test.com")
            .rol(Rol.ADMIN)
            .build();

    @Test
    void generaTokenValidoConEmailComoSubject() {
        JwtService jwt = new JwtService(SECRET, 60_000);

        String token = jwt.generarToken(usuario);

        assertThat(jwt.extraerEmail(token)).isEqualTo("ana@test.com");
        assertThat(jwt.esValido(token, "ana@test.com")).isTrue();
        assertThat(jwt.esValido(token, "otro@test.com")).isFalse();
    }

    @Test
    void rechazaTokenFirmadoConOtraClave() {
        String token = new JwtService(SECRET, 60_000).generarToken(usuario);
        JwtService otro = new JwtService("otra-clave-distinta-de-al-menos-32-caracteres-xx", 60_000);

        assertThatThrownBy(() -> otro.extraerEmail(token)).isInstanceOf(Exception.class);
    }

    @Test
    void tokenExpiradoNoEsValido() {
        JwtService jwt = new JwtService(SECRET, -1_000);
        String token = jwt.generarToken(usuario);

        assertThatThrownBy(() -> jwt.esValido(token, "ana@test.com")).isInstanceOf(Exception.class);
    }
}
