package com.utesa.api.infrastructure.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

/**
 * Si existe la variable DATABASE_URL (la que entrega Neon y la que se guarda en
 * GitHub Secrets), tiene prioridad sobre DB_HOST/DB_USER/DB_PASSWORD de application.yml.
 * Sin DATABASE_URL todo sigue funcionando como antes (local / Docker Compose).
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String databaseUrl = environment.getProperty("DATABASE_URL");
        if (databaseUrl == null || databaseUrl.isBlank()) {
            return;
        }
        environment.getPropertySources()
                .addFirst(new MapPropertySource("databaseUrl", DatabaseUrlParser.parse(databaseUrl)));
    }
}
