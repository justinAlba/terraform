package com.utesa.api.infrastructure.in.web;

import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.in.AuthUseCase;
import com.utesa.api.infrastructure.in.web.dto.LoginRequest;
import com.utesa.api.infrastructure.in.web.dto.RegistroRequest;
import com.utesa.api.infrastructure.in.web.dto.TokenResponse;
import com.utesa.api.infrastructure.in.web.dto.UsuarioResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthUseCase authUseCase;

    @PostMapping("/registro")
    public ResponseEntity<UsuarioResponse> registrar(@Valid @RequestBody RegistroRequest request) {
        Usuario usuario = authUseCase.registrar(request.nombre(), request.email(), request.password());
        return ResponseEntity.status(HttpStatus.CREATED).body(UsuarioResponse.desde(usuario));
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        String token = authUseCase.login(request.email(), request.password());
        return ResponseEntity.ok(TokenResponse.of(token));
    }
}
