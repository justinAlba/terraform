package com.utesa.api.domain.port.out;

import com.utesa.api.domain.model.Usuario;

public interface TokenProviderPort {

    String generarToken(Usuario usuario);
}
