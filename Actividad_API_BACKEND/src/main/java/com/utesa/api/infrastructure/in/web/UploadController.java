package com.utesa.api.infrastructure.in.web;

import com.utesa.api.infrastructure.in.web.dto.UploadResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class UploadController {

    private final Path uploadDir;

    public UploadController(@Value("${app.upload-dir}") String uploadDir) throws IOException {
        this.uploadDir = Path.of(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(this.uploadDir);
    }

    @PostMapping
    public ResponseEntity<UploadResponse> subir(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El archivo esta vacio");
        }

        String extension = "";
        String nombreOriginal = StringUtils.cleanPath(file.getOriginalFilename() != null ? file.getOriginalFilename() : "");
        int idx = nombreOriginal.lastIndexOf('.');
        if (idx >= 0) {
            extension = nombreOriginal.substring(idx);
        }

        String nombreGuardado = UUID.randomUUID() + extension;

        try {
            Path destino = uploadDir.resolve(nombreGuardado).normalize();
            file.transferTo(destino);
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo guardar el archivo", ex);
        }

        UploadResponse respuesta = new UploadResponse(nombreGuardado, "/uploads/" + nombreGuardado);
        return ResponseEntity.status(HttpStatus.CREATED).body(respuesta);
    }
}
