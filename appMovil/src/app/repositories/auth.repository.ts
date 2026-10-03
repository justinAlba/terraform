import { Injectable } from '@angular/core';
import { jwtDecode } from 'jwt-decode';
import { Observable, from, switchMap, map } from 'rxjs';
import { JwtPayload, LoginRequest, RegistroRequest, TokenResponse } from '../core/models/auth.model';
import { Usuario } from '../core/models/usuario.model';
import { AuthService } from '../core/services/auth.service';
import { TokenStorageService } from '../core/services/token-storage.service';

@Injectable({ providedIn: 'root' })
export class AuthRepository {
  constructor(private authService: AuthService, private tokenStorage: TokenStorageService) {}

  login(body: LoginRequest): Observable<TokenResponse> {
    return this.authService.login(body).pipe(
      switchMap((respuesta) => from(this.tokenStorage.setToken(respuesta.token)).pipe(map(() => respuesta)))
    );
  }

  registrar(body: RegistroRequest): Observable<Usuario> {
    return this.authService.registrar(body);
  }

  logout(): Promise<void> {
    return this.tokenStorage.clearToken();
  }

  estaAutenticado(): Promise<boolean> {
    return this.tokenStorage.getToken().then((token) => !!token);
  }

  async obtenerUsuarioActual(): Promise<JwtPayload | null> {
    const token = await this.tokenStorage.getToken();
    if (!token) {
      return null;
    }
    try {
      return jwtDecode<JwtPayload>(token);
    } catch {
      return null;
    }
  }
}
