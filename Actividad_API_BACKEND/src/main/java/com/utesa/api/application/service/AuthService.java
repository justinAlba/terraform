package com.utesa.api.application.service;

import com.utesa.api.domain.exception.EmailDuplicadoException;
import com.utesa.api.domain.model.Rol;
import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.in.AuthUseCase;
import com.utesa.api.domain.port.out.TokenProviderPort;
import com.utesa.api.domain.port.out.UsuarioRepositoryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AuthService implements AuthUseCase {

    private final UsuarioRepositoryPort usuarioRepositoryPort;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final TokenProviderPort tokenProviderPort;

    @Override
    public Usuario registrar(String nombre, String email, String password) {
        if (usuarioRepositoryPort.existePorEmail(email)) {
            throw new EmailDuplicadoException(email);
        }
        Usuario usuario = Usuario.builder()
                .nombre(nombre)
                .email(email)
                .password(passwordEncoder.encode(password))
                .rol(Rol.USUARIO)
                .fechaCreacion(Instant.now())
                .build();
        return usuarioRepositoryPort.guardar(usuario);
    }

    @Override
    public String login(String email, String password) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, password));

        Usuario usuario = usuarioRepositoryPort.buscarPorEmail(email)
                .orElseThrow(() -> new IllegalStateException("Usuario autenticado no encontrado"));

        return tokenProviderPort.generarToken(usuario);
    }
}
