package com.utesa.api.domain.exception;

public class EmailDuplicadoException extends RuntimeException {

    public EmailDuplicadoException(String email) {
        super("Ya existe un usuario registrado con el email: " + email);
    }
}
