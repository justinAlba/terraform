import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { LoginRequest, RegistroRequest, TokenResponse } from '../models/auth.model';
import { Usuario } from '../models/usuario.model';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly baseUrl = '/api/auth';

  constructor(private http: HttpClient) {}

  login(body: LoginRequest): Observable<TokenResponse> {
    return this.http.post<TokenResponse>(`${this.baseUrl}/login`, body);
  }

  registrar(body: RegistroRequest): Observable<Usuario> {
    return this.http.post<Usuario>(`${this.baseUrl}/registro`, body);
  }
}
