package com.utesa.api.infrastructure.in.web;

import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.in.UsuarioUseCase;
import com.utesa.api.infrastructure.in.web.dto.UsuarioRequest;
import com.utesa.api.infrastructure.in.web.dto.UsuarioResponse;
import com.utesa.api.infrastructure.in.web.dto.UsuarioUpdateRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioUseCase usuarioUseCase;

    @PostMapping
    public ResponseEntity<UsuarioResponse> crear(@Valid @RequestBody UsuarioRequest request) {
        Usuario usuario = Usuario.builder()
                .nombre(request.nombre())
                .email(request.email())
                .password(request.password())
                .rol(request.rol())
                .build();
        Usuario creado = usuarioUseCase.crear(usuario);
        return ResponseEntity.status(HttpStatus.CREATED).body(UsuarioResponse.desde(creado));
    }

    @GetMapping
    public ResponseEntity<List<UsuarioResponse>> listar() {
        List<UsuarioResponse> usuarios = usuarioUseCase.listarTodos().stream()
                .map(UsuarioResponse::desde)
                .toList();
        return ResponseEntity.ok(usuarios);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(UsuarioResponse.desde(usuarioUseCase.obtenerPorId(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponse> actualizar(@PathVariable Long id,
                                                        @Valid @RequestBody UsuarioUpdateRequest request) {
        Usuario usuario = Usuario.builder()
                .nombre(request.nombre())
                .email(request.email())
                .password(request.password())
                .rol(request.rol())
                .build();
        Usuario actualizado = usuarioUseCase.actualizar(id, usuario);
        return ResponseEntity.ok(UsuarioResponse.desde(actualizado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        usuarioUseCase.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
