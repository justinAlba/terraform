import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Usuario, UsuarioRequest, UsuarioUpdateRequest } from '../core/models/usuario.model';
import { UsuarioService } from '../core/services/usuario.service';

@Injectable({ providedIn: 'root' })
export class UsuarioRepository {
  constructor(private usuarioService: UsuarioService) {}

  listar(): Observable<Usuario[]> {
    return this.usuarioService.listar();
  }

  obtenerPorId(id: number): Observable<Usuario> {
    return this.usuarioService.obtenerPorId(id);
  }

  crear(body: UsuarioRequest): Observable<Usuario> {
    return this.usuarioService.crear(body);
  }

  actualizar(id: number, body: UsuarioUpdateRequest): Observable<Usuario> {
    return this.usuarioService.actualizar(id, body);
  }

  eliminar(id: number): Observable<void> {
    return this.usuarioService.eliminar(id);
  }
}
