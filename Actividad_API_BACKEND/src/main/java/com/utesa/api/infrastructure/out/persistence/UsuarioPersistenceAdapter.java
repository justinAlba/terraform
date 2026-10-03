package com.utesa.api.infrastructure.out.persistence;

import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.out.UsuarioRepositoryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class UsuarioPersistenceAdapter implements UsuarioRepositoryPort {

    private final UsuarioJpaRepository usuarioJpaRepository;

    @Override
    public Usuario guardar(Usuario usuario) {
        UsuarioJpaEntity entidad = toEntity(usuario);
        return toDomain(usuarioJpaRepository.save(entidad));
    }

    @Override
    public Optional<Usuario> buscarPorId(Long id) {
        return usuarioJpaRepository.findById(id).map(UsuarioPersistenceAdapter::toDomain);
    }

    @Override
    public Optional<Usuario> buscarPorEmail(String email) {
        return usuarioJpaRepository.findByEmail(email).map(UsuarioPersistenceAdapter::toDomain);
    }

    @Override
    public List<Usuario> buscarTodos() {
        return usuarioJpaRepository.findAll().stream()
                .map(UsuarioPersistenceAdapter::toDomain)
                .toList();
    }

    @Override
    public void eliminarPorId(Long id) {
        usuarioJpaRepository.deleteById(id);
    }

    @Override
    public boolean existePorEmail(String email) {
        return usuarioJpaRepository.existsByEmail(email);
    }

    private static UsuarioJpaEntity toEntity(Usuario usuario) {
        return UsuarioJpaEntity.builder()
                .id(usuario.getId())
                .nombre(usuario.getNombre())
                .email(usuario.getEmail())
                .password(usuario.getPassword())
                .rol(usuario.getRol())
                .fechaCreacion(usuario.getFechaCreacion())
                .build();
    }

    private static Usuario toDomain(UsuarioJpaEntity entidad) {
        return Usuario.builder()
                .id(entidad.getId())
                .nombre(entidad.getNombre())
                .email(entidad.getEmail())
                .password(entidad.getPassword())
                .rol(entidad.getRol())
                .fechaCreacion(entidad.getFechaCreacion())
                .build();
    }
}
