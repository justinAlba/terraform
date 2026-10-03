package com.utesa.api.infrastructure.out.storage;

import com.utesa.api.domain.port.out.AlmacenamientoArchivosPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Guarda en disco (ejecucion local y Docker). Los archivos se sirven en /uploads/** via WebConfig.
 */
@Component
@ConditionalOnProperty(name = "app.storage", havingValue = "local", matchIfMissing = true)
public class LocalAlmacenamientoAdapter implements AlmacenamientoArchivosPort {

    private final Path uploadDir;

    public LocalAlmacenamientoAdapter(@Value("${app.upload-dir}") String uploadDir) throws IOException {
        this.uploadDir = Path.of(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(this.uploadDir);
    }

    @Override
    public String guardar(String nombre, String contentType, InputStream contenido, long tamano) throws IOException {
        Files.copy(contenido, uploadDir.resolve(nombre).normalize());
        return "/uploads/" + nombre;
    }
}
