package com.utesa.api.infrastructure.in.web;

import com.utesa.api.domain.port.out.AlmacenamientoArchivosPort;
import com.utesa.api.infrastructure.in.web.dto.UploadResponse;
import lombok.RequiredArgsConstructor;
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
import java.io.InputStream;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class UploadController {

    private final AlmacenamientoArchivosPort almacenamiento;

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

        String url;
        try (InputStream contenido = file.getInputStream()) {
            url = almacenamiento.guardar(nombreGuardado, file.getContentType(), contenido, file.getSize());
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo guardar el archivo", ex);
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(new UploadResponse(nombreGuardado, url));
    }
}
