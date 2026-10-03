package com.utesa.api.domain.port.in;

import com.utesa.api.domain.model.Usuario;

public interface AuthUseCase {

    Usuario registrar(String nombre, String email, String password);

    String login(String email, String password);
}
