package com.utesa.api.infrastructure.config;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Convierte una URL estilo Neon/Supabase
 * (postgresql://usuario:clave@host:puerto/base?sslmode=require)
 * en las propiedades spring.datasource.* que entiende el driver JDBC.
 */
public final class DatabaseUrlParser {

    private DatabaseUrlParser() {
    }

    public static Map<String, Object> parse(String databaseUrl) {
        Map<String, Object> props = new LinkedHashMap<>();
        String url = databaseUrl.trim();

        if (url.startsWith("jdbc:")) {
            props.put("spring.datasource.url", url);
            return props;
        }

        URI uri = URI.create(url);
        String scheme = uri.getScheme();
        if (!"postgres".equals(scheme) && !"postgresql".equals(scheme)) {
            throw new IllegalArgumentException("DATABASE_URL debe empezar con postgresql:// o jdbc:");
        }

        int puerto = uri.getPort() > 0 ? uri.getPort() : 5432;
        StringBuilder jdbc = new StringBuilder("jdbc:postgresql://")
                .append(uri.getHost()).append(':').append(puerto)
                .append(uri.getRawPath());

        String query = filtrarQuery(uri.getRawQuery());
        if (!query.isEmpty()) {
            jdbc.append('?').append(query);
        }
        props.put("spring.datasource.url", jdbc.toString());

        String userInfo = uri.getRawUserInfo();
        if (userInfo != null) {
            int idx = userInfo.indexOf(':');
            String usuario = idx >= 0 ? userInfo.substring(0, idx) : userInfo;
            props.put("spring.datasource.username", decodificar(usuario));
            if (idx >= 0) {
                props.put("spring.datasource.password", decodificar(userInfo.substring(idx + 1)));
            }
        }
        return props;
    }

    // channel_binding es un parametro de libpq que el driver JDBC no reconoce.
    private static String filtrarQuery(String query) {
        if (query == null || query.isBlank()) {
            return "";
        }
        return Arrays.stream(query.split("&"))
                .filter(param -> !param.startsWith("channel_binding="))
                .collect(Collectors.joining("&"));
    }

    private static String decodificar(String valor) {
        return URLDecoder.decode(valor, StandardCharsets.UTF_8);
    }
}
