package com.utesa.api.domain.port.in;

import com.utesa.api.domain.model.Usuario;

import java.util.List;

public interface UsuarioUseCase {

    Usuario crear(Usuario usuario);

    Usuario obtenerPorId(Long id);

    List<Usuario> listarTodos();

    Usuario actualizar(Long id, Usuario usuario);

    void eliminar(Long id);
}
