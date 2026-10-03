package com.utesa.api.infrastructure.config;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DatabaseUrlParserTest {

    @Test
    void convierteUrlDeNeonAJdbc() {
        Map<String, Object> props = DatabaseUrlParser.parse(
                "postgresql://neondb_owner:abc123@ep-cool-name.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require");

        assertThat(props)
                .containsEntry("spring.datasource.url",
                        "jdbc:postgresql://ep-cool-name.us-east-1.aws.neon.tech:5432/neondb?sslmode=require")
                .containsEntry("spring.datasource.username", "neondb_owner")
                .containsEntry("spring.datasource.password", "abc123");
    }

    @Test
    void respetaPuertoYDecodificaClave() {
        Map<String, Object> props = DatabaseUrlParser.parse("postgres://admin:p%40ss%3Aword@db.example.com:6543/app");

        assertThat(props)
                .containsEntry("spring.datasource.url", "jdbc:postgresql://db.example.com:6543/app")
                .containsEntry("spring.datasource.password", "p@ss:word");
    }

    @Test
    void dejaPasarUrlJdbc() {
        Map<String, Object> props = DatabaseUrlParser.parse("jdbc:postgresql://localhost:5432/actividad_api");

        assertThat(props)
                .containsOnlyKeys("spring.datasource.url")
                .containsEntry("spring.datasource.url", "jdbc:postgresql://localhost:5432/actividad_api");
    }

    @Test
    void rechazaEsquemaDesconocido() {
        assertThatThrownBy(() -> DatabaseUrlParser.parse("mysql://u:p@host/db"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
