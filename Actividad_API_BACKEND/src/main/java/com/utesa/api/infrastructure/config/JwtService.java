package com.utesa.api.infrastructure.config;

import com.utesa.api.domain.model.Usuario;
import com.utesa.api.domain.port.out.TokenProviderPort;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService implements TokenProviderPort {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(@Value("${jwt.secret}") String secret,
                       @Value("${jwt.expiration-ms}") long expirationMs) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    @Override
    public String generarToken(Usuario usuario) {
        Date ahora = new Date();
        Date expiracion = new Date(ahora.getTime() + expirationMs);

        return Jwts.builder()
                .subject(usuario.getEmail())
                .claim("rol", usuario.getRol().name())
                .claim("id", usuario.getId())
                .issuedAt(ahora)
                .expiration(expiracion)
                .signWith(signingKey)
                .compact();
    }

    public String extraerEmail(String token) {
        return extraerClaims(token).getSubject();
    }

    public boolean esValido(String token, String email) {
        Claims claims = extraerClaims(token);
        return claims.getSubject().equals(email) && claims.getExpiration().after(new Date());
    }

    private Claims extraerClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
