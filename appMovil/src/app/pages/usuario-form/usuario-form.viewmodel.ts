import { HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Rol } from '../../core/models/usuario.model';
import { UsuarioRepository } from '../../repositories/usuario.repository';

@Injectable()
export class UsuarioFormViewModel {
  readonly cargando$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);
  readonly guardado$ = new BehaviorSubject<boolean>(false);

  constructor(private usuarioRepository: UsuarioRepository) {}

  cargarUsuario(id: number, alCargar: (datos: { nombre: string; email: string; rol: Rol }) => void): void {
    this.cargando$.next(true);
    this.usuarioRepository.obtenerPorId(id).subscribe({
      next: (usuario) => {
        this.cargando$.next(false);
        alCargar({ nombre: usuario.nombre, email: usuario.email, rol: usuario.rol });
      },
      error: () => {
        this.cargando$.next(false);
        this.error$.next('No se pudo cargar el usuario.');
      },
    });
  }

  crear(nombre: string, email: string, password: string, rol: Rol): void {
    this.cargando$.next(true);
    this.error$.next(null);
    this.usuarioRepository.crear({ nombre, email, password, rol }).subscribe({
      next: () => {
        this.cargando$.next(false);
        this.guardado$.next(true);
      },
      error: (error: HttpErrorResponse) => {
        this.cargando$.next(false);
        this.error$.next(this.mapearError(error));
      },
    });
  }

  actualizar(id: number, nombre: string, email: string, password: string | null, rol: Rol): void {
    this.cargando$.next(true);
    this.error$.next(null);
    this.usuarioRepository
      .actualizar(id, { nombre, email, rol, ...(password ? { password } : {}) })
      .subscribe({
        next: () => {
          this.cargando$.next(false);
          this.guardado$.next(true);
        },
        error: (error: HttpErrorResponse) => {
          this.cargando$.next(false);
          this.error$.next(this.mapearError(error));
        },
      });
  }

  private mapearError(error: HttpErrorResponse): string {
    if (error.status === 409) {
      return 'Ya existe un usuario con ese correo.';
    }
    if (error.status === 400) {
      return 'Revisa los datos ingresados.';
    }
    return 'No se pudo guardar el usuario. Intenta de nuevo.';
  }
}
