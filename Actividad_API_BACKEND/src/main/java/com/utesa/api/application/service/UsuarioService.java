package com.utesa.api.application.service;

import com.utesa.api.domain.exception.EmailDuplicadoException;
import com.utesa.api.domain.exception.UsuarioNotFoundException;
import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.in.UsuarioUseCase;
import com.utesa.api.domain.port.out.UsuarioRepositoryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UsuarioService implements UsuarioUseCase {

    private final UsuarioRepositoryPort usuarioRepositoryPort;
    private final PasswordEncoder passwordEncoder;

    @Override
    public Usuario crear(Usuario usuario) {
        if (usuarioRepositoryPort.existePorEmail(usuario.getEmail())) {
            throw new EmailDuplicadoException(usuario.getEmail());
        }
        usuario.setPassword(passwordEncoder.encode(usuario.getPassword()));
        usuario.setFechaCreacion(Instant.now());
        return usuarioRepositoryPort.guardar(usuario);
    }

    @Override
    public Usuario obtenerPorId(Long id) {
        return usuarioRepositoryPort.buscarPorId(id)
                .orElseThrow(() -> new UsuarioNotFoundException(id));
    }

    @Override
    public List<Usuario> listarTodos() {
        return usuarioRepositoryPort.buscarTodos();
    }

    @Override
    public Usuario actualizar(Long id, Usuario usuario) {
        Usuario existente = obtenerPorId(id);

        if (!existente.getEmail().equalsIgnoreCase(usuario.getEmail())
                && usuarioRepositoryPort.existePorEmail(usuario.getEmail())) {
            throw new EmailDuplicadoException(usuario.getEmail());
        }

        existente.setNombre(usuario.getNombre());
        existente.setEmail(usuario.getEmail());
        existente.setRol(usuario.getRol());
        if (usuario.getPassword() != null && !usuario.getPassword().isBlank()) {
            existente.setPassword(passwordEncoder.encode(usuario.getPassword()));
        }
        return usuarioRepositoryPort.guardar(existente);
    }

    @Override
    public void eliminar(Long id) {
        obtenerPorId(id);
        usuarioRepositoryPort.eliminarPorId(id);
    }
}
