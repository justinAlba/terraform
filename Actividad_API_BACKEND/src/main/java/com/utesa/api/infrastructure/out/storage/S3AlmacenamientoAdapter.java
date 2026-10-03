package com.utesa.api.infrastructure.out.storage;

import com.utesa.api.domain.port.out.AlmacenamientoArchivosPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetUrlRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.InputStream;

/**
 * Guarda en S3 (despliegue en Lambda, donde el disco es efimero).
 * La region y las credenciales salen del entorno de Lambda (rol IAM creado por Terraform).
 */
@Component
@ConditionalOnProperty(name = "app.storage", havingValue = "s3")
public class S3AlmacenamientoAdapter implements AlmacenamientoArchivosPort {

    private final S3Client s3;
    private final String bucket;
    private final String prefijo;

    public S3AlmacenamientoAdapter(@Value("${app.s3.bucket}") String bucket,
                                   @Value("${app.s3.prefix}") String prefijo) {
        this.s3 = S3Client.builder()
                .httpClient(UrlConnectionHttpClient.create())
                .build();
        this.bucket = bucket;
        this.prefijo = prefijo;
    }

    @Override
    public String guardar(String nombre, String contentType, InputStream contenido, long tamano) {
        String key = prefijo + nombre;
        s3.putObject(PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType(contentType)
                        .build(),
                RequestBody.fromInputStream(contenido, tamano));

        return s3.utilities()
                .getUrl(GetUrlRequest.builder().bucket(bucket).key(key).build())
                .toExternalForm();
    }
}
