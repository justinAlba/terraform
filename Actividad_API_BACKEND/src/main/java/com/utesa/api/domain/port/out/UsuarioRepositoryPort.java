package com.utesa.api.domain.port.out;

import com.utesa.api.domain.model.Usuario;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepositoryPort {

    Usuario guardar(Usuario usuario);

    Optional<Usuario> buscarPorId(Long id);

    Optional<Usuario> buscarPorEmail(String email);

    List<Usuario> buscarTodos();

    void eliminarPorId(Long id);

    boolean existePorEmail(String email);
}
