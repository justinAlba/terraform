package com.utesa.api.domain.port.out;

import java.io.IOException;
import java.io.InputStream;

public interface AlmacenamientoArchivosPort {

    /**
     * Guarda el archivo y devuelve la URL con la que el cliente puede descargarlo.
     */
    String guardar(String nombre, String contentType, InputStream contenido, long tamano) throws IOException;
}
