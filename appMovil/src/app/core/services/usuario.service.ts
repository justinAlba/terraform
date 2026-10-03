import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Usuario, UsuarioRequest, UsuarioUpdateRequest } from '../models/usuario.model';

@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private readonly baseUrl = '/api/usuarios';

  constructor(private http: HttpClient) {}

  listar(): Observable<Usuario[]> {
    return this.http.get<Usuario[]>(this.baseUrl);
  }

  obtenerPorId(id: number): Observable<Usuario> {
    return this.http.get<Usuario>(`${this.baseUrl}/${id}`);
  }

  crear(body: UsuarioRequest): Observable<Usuario> {
    return this.http.post<Usuario>(this.baseUrl, body);
  }

  actualizar(id: number, body: UsuarioUpdateRequest): Observable<Usuario> {
    return this.http.put<Usuario>(`${this.baseUrl}/${id}`, body);
  }

  eliminar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
